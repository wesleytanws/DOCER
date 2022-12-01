from numpy import where
from pandas import DataFrame, read_csv
from pathlib import Path

input_dir = 'output'
output_dir = 'report/new'

# Create output directories
Path(f"{output_dir}/extended").mkdir(parents=True, exist_ok=True)

repo_list = open('new_projects.txt').read().splitlines()

for repo_idx, repo_name in enumerate(repo_list, start=1):

    print(f"{repo_idx}. {repo_name}")

    repo_outname = repo_name.replace('/', '_')
    report_outfile = f"{output_dir}/extended/{repo_outname}_all.csv"

    # Read CSV files from the input directory
    matches = read_csv(f"{input_dir}/{repo_name}/all_matches.csv", keep_default_na=False)
    pages = read_csv(f"{input_dir}/{repo_name}/all_pages.csv", keep_default_na=False)
    revisions = read_csv(f"{input_dir}/{repo_name}/all_revisions.csv", keep_default_na=False)
    sources = read_csv(f"{input_dir}/{repo_name}/all_sources.csv", keep_default_na=False)

    # Remove files if there are no results
    if not len(matches):
        Path(report_outfile).unlink(missing_ok=True)
        continue

    # Link to source code on GitHub
    sources = sources.merge(revisions[['page_id', 'rev_id', 'rev_SHA']])
    sources = sources.sort_values(by=['rev_id', 'file_name'], ascending=False)
    sources = sources.drop_duplicates(subset=['page_id', 'code_element'])
    sources['source_link'] = f"https://github.com/{repo_name}/blob/" + \
                            sources['rev_SHA'] + '/' + sources['file_name'] + \
                            '#L' + sources['line_number'].astype(str)

    # Reshape revisions as columns, group by pages, select timestamp and SHA
    details = revisions.pivot(index='page_id', columns='rev_id')

    # Rename columns (rev_col, id) as rev_col_id
    details.columns = details.columns.map('{0[0]}_{0[1]}'.format)
    details_cols = sorted(details.columns.tolist(), \
        key=lambda col_name: int(col_name.split('_')[-1]))

    # Combine details in pivot table with the original DataFrame
    details = DataFrame(details.to_records()).merge(pages)
    details = details.reindex(columns=['page_id', 'page_type', 'page_name', *details_cols])

    # Link to the documentation on GitHub
    doc_SHA = details[[col for col in details if col.startswith('doc_SHA')]]
    latest_doc = doc_SHA[doc_SHA.columns[::-1]].notna().idxmax(axis=1)

    # Remove files if there are no results
    if not len(latest_doc):
        Path(report_outfile).unlink(missing_ok=True)
        continue

    # Create columns for missing revisions
    doc_cols = [f"doc_SHA_{i+1}" for i in range(revisions['rev_id'].max())]
    doc_SHA = doc_SHA.reindex(columns=doc_cols)

    doc_SHA = doc_SHA.values[range(len(details)), \
        latest_doc.str.split('_').str[-1].astype(int).sub(1)]

    details['doc_link'] = where(details['page_type'] == 'repo', \

        # Repository
        f"https://github.com/{repo_name}/blob/" + \
        doc_SHA + '/' + details['page_name'], \

        # Wiki
        f"https://github.com/{repo_name}/wiki/" + \
        details['page_name'].str.rsplit('.', 1).str[0] + '/' + doc_SHA)

    # Reshape revisions as columns, group by code elements and pages
    matches = matches.groupby(['code_element', 'page_id', 'rev_id'])['count'].sum().unstack('rev_id')

    # Remove rows that are only either 0 or NaN
    matches = matches.loc[~(matches.isna() | matches.eq(0)).all(axis=1)]

    # Remove files if there are no results
    if not len(matches):
        Path(report_outfile).unlink(missing_ok=True)
        continue

    # Rename columns (count, id) as rev_id
    matches.columns = ['rev_' + str(col) for col in matches.columns]

    # Create columns for missing revisions
    rev_cols = [f"rev_{i+1}" for i in range(revisions['rev_id'].max())]
    matches = matches.reindex(columns=rev_cols)

    # Include these columns in the output
    output_cols = ['code_element', 'page_type', 'page_name', *rev_cols, \
        'doc_link', 'source_link']

    # Convert pivot table to DataFrame
    report = DataFrame(matches.to_records())

    # Fill in NaN values with '-' if page is found in revision
    for _, (page_id, revision_id) in revisions[['page_id', 'rev_id']].iterrows():
        report.loc[report['page_id'] == page_id, f"rev_{revision_id}"] = report.loc[report['page_id'] == page_id, f"rev_{revision_id}"].fillna('-')

    # Combine pivot table with DataFrame as output
    report = report.merge(details)
    report = report.fillna('.')
    report = report.merge(sources[['page_id', 'code_element', 'source_link']], how='left')
    report = report.fillna('code_element is a file name')
    report = report.sort_values(by=['page_type', 'page_name', 'code_element'])

    for col in matches.columns:
        no_decimal_col = report[col].astype(str).str.replace('.0', '', regex=False)
        report[col] = no_decimal_col

    report.to_csv(report_outfile, columns=output_cols, index=None)
