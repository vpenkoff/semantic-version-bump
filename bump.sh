#!/bin/sh
###############################################################################
## semantic version bump based on git
## author: Viktor Penkov
## Description: simple script to tag the release branch with semantic versioning
## It gets the commits between the HEAD and the last tag and search for one of
## [ *major*,  *minor*, *patch* ] in the commit log. Then it checks for which
## part we have commits and increments by one.
## Example A:
## Let's say we have version 2.3.4 and we found 3 commits having "*major*" in
## their names. Our next semantic version would look like as follow:
##  3.0.0
## Exambple B:
## Let's say we have version 2.3.4 and we found 5 commits having "*minor*" in
## their names. Our next semantic version would look likes as follow:
##  2.4.0
## Example C:
## Let's say we have version 2.3.4 and we have 20 commits having "*patch*" in
## their names. Our next semantic version would look like as follow:
##  2.3.5
## Example D:
## Let's say we don't have any tags available. Then our semantic version would
## fall back to the default set one, i.e. 3.0.0
##
###############################################################################

set -e

default_version="3.0.0"
default_major_version="3"
git_tag_cmd="git tag"

last_git_tag=$(git describe --tags --abbrev=0)

major_version=$(echo $last_git_tag | cut -d "." -f 1)
minor_version=$(echo $last_git_tag | cut -d "." -f 2)
patch_version=$(echo $last_git_tag | cut -d "." -f 3)

commits_between_tags_major=$(git log HEAD...$last_git_tag --pretty --format=oneline --grep="\*major\*")
commits_between_tags_minor=$(git log HEAD...$last_git_tag --pretty --format=oneline --grep="\*minor\*")
commits_between_tags_patch=$(git log HEAD...$last_git_tag --pretty --format=oneline --grep="\*patch\*")

count_commits_between_tags_major=$(echo "$commits_between_tags_major" | sed '/^\s*$/d' | wc -l | awk '{ print $1 }')
count_commits_between_tags_minor=$(echo "$commits_between_tags_minor" | sed '/^\s*$/d' | wc -l | awk '{ print $1 }')
count_commits_between_tags_patch=$(echo "$commits_between_tags_patch" | sed '/^\s*$/d' | wc -l | awk '{ print $1 }')

bump_version() {
  current_version=$1

  if [ -z $current_version ]; then
  return
  fi

  echo $(expr $current_version + 1)
  return
}

get_semantic_version() {
  if [ -z "$major_version" ]; then
  echo $default_version
  return
  fi

  if [ "$major_version" -lt "$default_major_version" ]; then
  echo $default_version
  return
  fi

  if [ "$count_commits_between_tags_major" -gt 0 ]; then
  major_version=$(bump_version $major_version )
  echo "$major_version.0.0"
  return
  fi

  if [ "$count_commits_between_tags_minor" -gt 0 ]; then
  minor_version=$(bump_version $minor_version )
  echo "$major_version.$minor_version.0"
  return
  fi

  if [ "$count_commits_between_tags_patch" -gt 0 ]; then
  patch_version=$(bump_version $patch_version)
  echo "$major_version.$minor_version.$patch_version"
  return
  fi

  echo $default_version
}

print_semantic_commits() {
  echo "Latest commits:"
  echo "Major version commits: $count_commits_between_tags_major"
  echo "$commits_between_tags_major"
  echo "Minor version commints: $count_commits_between_tags_minor"
  echo "$commits_between_tags_minor"
  echo "Patch version commits: $count_commits_between_tags_patch"
  echo "$commits_between_tags_patch"
}

main() {
  print_semantic_commits
  new_tag=$(get_semantic_version)
  echo "Tagging the release with version $new_tag"
  $($git_tag_cmd $new_tag)
  echo "Done!"
}

# run the script
main
