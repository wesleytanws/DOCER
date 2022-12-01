#!/usr/bin/env bash

run_evaluate() {

    # Set input and output directories
    input_dir="dataset"
    output_dir="output"

    # List of regular expressions to match code elements
    regex_path="regex_list.txt"

    # Create temporary output directory
    mkdir -p -- "$output_dir/tmp"

    export input_dir
    export output_dir
    export regex_path

    parallel -j 1 evaluate_repo :::: <(
        awk '{ print NR, $0 }' < new_projects.txt
    )

    # Replace old output files and clean up temporary directory
    cp -r -- "$output_dir"/tmp/* "$output_dir"
    rm -r -- "$output_dir"/tmp/
}

evaluate_repo() {

    read -r repo_id repo_name < <(printf '%s' "$1")

    printf '%s\n' "$repo_id. $repo_name"

    # Set directories for the current repository
    project_dir="$input_dir/$repo_name"
    repo_dir="$project_dir/repo"
    wiki_dir="$project_dir/wiki"

    # Create temporary output directory for the current repository
    mkdir -p -- "$output_dir/tmp/$repo_name"

    # Print headers for the CSV output files
    printf '%s\n' "page_id,rev_id,code_element,count" > "$output_dir/tmp/$repo_name/all_matches.csv"
    printf '%s\n' "page_id,rev_id,code_element,file_name,line_number" > "$output_dir/tmp/$repo_name/all_sources.csv"
    printf '%s\n' "page_id,page_type,page_name" > "$output_dir/tmp/$repo_name/all_pages.csv"
    printf '%s\n' "page_id,rev_id,rev_SHA,rev_timestamp,doc_SHA,doc_timestamp" > "$output_dir/tmp/$repo_name/all_revisions.csv"

    export repo_name
    export repo_dir
    export wiki_dir

    parallel -0 -j 1 evaluate_page :::: <({

        # Find README.md in the source code repository
        awk 'BEGIN { RS="\0"; ORS="\0" }; { print 0, $0 }' <(
            grep -axzF README.md <( # Match README.md in the root directory
                sort -uz <( # Sort unique page names
                    git -C "$repo_dir" log --first-parent --pretty=format: -z --name-only HEAD 2> /dev/null
                )
            )
        );

        # Find documentation files in the wiki repository
        awk 'BEGIN { RS="\0"; ORS="\0" }; { print NR, $0 }' <(
            grep -aivzE "(^|\/)_[^\/]*\." <( # Match file names that do not start with '_'
                # Match a list of valid markup extensions: https://github.com/github/markup#markups
                grep -aizP "\.(markdown|mdown|mkdn|md|textile|rdoc|org|creole|mediawiki|wiki|rst|asciidoc|adoc|asc|pod)$" <(
                    sort -uz <( # Sort unique page names
                        git -C "$wiki_dir" log --first-parent --pretty=format: -z --name-only HEAD 2> /dev/null
                    )
                )
            )
        );
    })
}

evaluate_page() {

    IFS=' ' read -r -d $'\0' page_id page_name < <(printf '%s\0' "$1")

    # Set the directory to the page location
    if ((page_id == 0)); then
        page_dir="$repo_dir"
    else
        page_dir="$wiki_dir"
    fi

    printf '%s,%s,"%s"\n' "$page_id" "${page_dir##*/}" "${page_name//\"/\"\"}" >> "$output_dir/tmp/$repo_name/all_pages.csv"

    export page_id
    export page_dir
    export page_name

    parallel evaluate_revision :::: <(
        awk '{ print NR, $0 }' <(
            tac <(
                git -C "$repo_dir" rev-list --first-parent HEAD 2> /dev/null
            )
        )
    )
}

evaluate_revision() {

    read -r rev_id rev_SHA < <(printf '%s' "$1")

    rev_timestamp="$(git -C "$repo_dir" log -1 --first-parent --pretty=format:%ct "$rev_SHA")"
    doc_SHA="$(git -C "$page_dir" rev-list -1 --min-age="$rev_timestamp" --first-parent HEAD -- "./$page_name")"

    # Return early if documentation SHA is not found
    if ((!${#doc_SHA})); then return; fi

    doc_timestamp="$(git -C "$page_dir" log -1 --first-parent --pretty=format:%ct "$doc_SHA")"
    page_found="$(git -C "$page_dir" ls-tree "$doc_SHA" --name-only "./$page_name")"

    # Return early if page is not found
    if ((!${#page_found})); then return; fi

    printf '%s,%s,%s,%s,%s,%s\n' "$page_id" "$rev_id" "$rev_SHA" "$rev_timestamp" "$doc_SHA" "$doc_timestamp" >> "$output_dir/tmp/$repo_name/all_revisions.csv"

    # List of file names found in this revision
    file_names="$(
        tr '\0' '\n' < <( # Change delimiter from '\0' to '\n'
            sed -nz '/\n/!p' <( # Remove names containing newline
                sort -uz <(
                    git -C "$repo_dir" ls-tree -rz "$rev_SHA" --name-only;
                )
            )
        )
    )"

    # List of unique code elements in the current documentation page
    # that match the list of regular expressions provided
    code_elements="$(
        sort -u <(
            git -C "$page_dir" grep -howIP -f "$PWD/$regex_path" "$doc_SHA" -- "./$page_name"
        )
    )"

    # List of code elements in the repository (excluding ./README.md)
    # that match the code elements found in the documentation and file names
    matched_elements="$(
        sort <({
            # Search for code elements in the documentation
            git -C "$repo_dir" grep -howFI -f <(printf '%s' "$code_elements") "$rev_SHA" -- ':!./README.md';

            # Intersection of code elements and file names
            grep -xF -f <(printf '%s' "$code_elements") <(
                sed -r 's/(.*)/\/\1\n\1/g' <( # Duplicate path and prepend '/'
                    # Recursively get subpaths (path/to/file -> to/file -> file)
                    while ((${#file_names})); do
                        # Remove empty lines and print the file names
                        grep -v '^$' <(printf '%s' "$file_names")
                        file_names="$(
                            # Remove first part of the path component
                            sed -r 's/[^\/]*(\/|$)//' <(printf '%s' "$file_names")
                        )"
                    done
                )
            );
        })
    )"

    # Extract source information of code elements
    while IFS=: read -r -d '' SHA file_name; read -d '' line_number; read -r code_element; do
        printf '%s,%s,"%s","%s",%s\n' "$page_id" "$rev_id" "${code_element//\"/\"\"}" "${file_name//\"/\"\"}" "$line_number"
    done < <(
        git -C "$repo_dir" grep -aznowFI -f <(printf '%s' "$code_elements") "$rev_SHA" -- ':!./README.md'
    ) >> "$output_dir/tmp/$repo_name/all_sources.csv"

    # List of code elements that are not matched
    while read -r code_element; do
        printf '%s,%s,"%s",0\n' "$page_id" "$rev_id" "${code_element//\"/\"\"}"
    done < <(
        # Subtraction of matched elements from code elements
        grep -vxF -f <(printf '%s' "$matched_elements") <(printf '%s' "$code_elements")
    ) >> "$output_dir/tmp/$repo_name/all_matches.csv"

    # List of code elements that are matched
    while read -r count code_element; do
        printf '%s,%s,"%s",%s\n' "$page_id" "$rev_id" "${code_element//\"/\"\"}" "$count"
    done < <(
        # Count the occurrences of matched elements
        uniq -c <(printf '%s' "$matched_elements")
    ) >> "$output_dir/tmp/$repo_name/all_matches.csv"
}

export -f evaluate_repo
export -f evaluate_page
export -f evaluate_revision

run_evaluate
