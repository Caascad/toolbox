# Autoupdate

This script is designed to automatically update packages referenced in the Toolbox.

The workflow is pretty straightforward :
- For each package located in the [sources.json](../nix/sources.json) file, we look for a new release using the Github graphQL API
- If a new release is found, package details are updated using the `niv update <package> -v <version>` command
- Once potential updates are done, we then automatically create a merge request to preview the changes.

There is also a few things to consider :
- If the package does not have a `version` field in the `sources.json` file, we assume that we want to update it to the latest commit available.
- There is a blacklist system on the [configuration file](config.yml) to prevent certain packages from being updated.

## Known issues

To look for new version of a package, we search for releases on the github repository. The problem we have here is that sometime maintainers only create a tag when they release a new version. In that case this new version will not be returned by the Github API call. Releases and Tags are two seperate things on the Github point of view. We need to find a solution to handle this use case. One could be to retrieve tags and not releases but this would expose the risk of updating to non-stable version as some maintainers create tags for alpha, beta or release canditates.


