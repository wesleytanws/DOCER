dataset_path="dataset"
repo_list_path="new_projects.txt"

idx=0
timestamp=-1

while IFS= read -r repo_name; do

    ((idx++))
    printf '%s\n' "$idx. $repo_name"

    git clone "https://github.com/$repo_name.git" "$dataset_path/$repo_name/repo" && {

        checkout_SHA="$(git -C "$dataset_path/$repo_name/repo" rev-list -1 --min-age=$timestamp --first-parent HEAD)"

        if ((${#checkout_SHA})); then
            printf '%s\n' "Checking out $checkout_SHA from $dataset_path/$repo_name/repo..."
            git -C "$dataset_path/$repo_name/repo" checkout "$checkout_SHA"
        else
            printf '%s\n' "Removing $dataset_path/$repo_name/repo from $dataset_path"
            rm -r "$dataset_path/$repo_name/repo"
        fi
    }

    git clone "https://github.com/$repo_name.wiki.git" "$dataset_path/$repo_name/wiki" && {

        checkout_SHA="$(git -C "$dataset_path/$repo_name/wiki" rev-list -1 --min-age=$timestamp --first-parent HEAD)"

        if ((${#checkout_SHA})); then
            printf '%s\n' "Checking out $checkout_SHA from $dataset_path/$repo_name/wiki..."
            git -C "$dataset_path/$repo_name/wiki" checkout "$checkout_SHA"
        else
            printf '%s\n' "Removing $dataset_path/$repo_name/wiki from $dataset_path"
            rm -r "$dataset_path/$repo_name/wiki"
        fi
    }

done < "$repo_list_path"
