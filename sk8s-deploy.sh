#!/bin/sh

GIT_REPO_NAME=""

GIT_HOST=""
GIT_SSH_PORT=""
GIT_PROJECT=""

REPLACEMENT=""

FILE_NAME=""

LINE_IDENT=""

TAG=""

MAIN_BRANCH_NAME="master"

BRANCH_NAME_PARAM=false
BRANCH_NAME=$MAIN_BRANCH_NAME

MULTI_APP_PARAM=false
MULTI_APP=false

MULTI_APP_PR_PARAM=false
MULTI_APP_PR=false

PULL_REQUEST_URL=""

die() {
  echo "ERROR: $0 died because:"
  echo "-> $1"
  exit 1
}

clone() {
  GIT_URL=ssh://git@${GIT_HOST}:${GIT_SSH_PORT}/${GIT_PROJECT}/${GIT_REPO_NAME}.git
  # don't forget to generate ssh keys in our code repo and publish public key to swisscom bitbucket
  echo "--------------------------------------------------"
  echo "Cloning and updating ${GIT_URL}"
  if ! git clone "${GIT_URL}" "${GIT_REPO_NAME}" && [ -d "${GIT_REPO_NAME}" ] ; then
    echo "folder ${GIT_REPO_NAME} already exists"
  fi
  cd $GIT_REPO_NAME || die "cannot switch to folder ${GIT_REPO_NAME}"
  PULL_REQUEST_URL=`test -f ~/pr_href.txt && cat ~/pr_href.txt`  
  git checkout $MAIN_BRANCH_NAME || die "having problems checkout ${MAIN_BRANCH_NAME}"
}

replace() {
  echo "--------------------------------------------------"
  echo "Setting ${LINE_IDENT} to ${REPLACEMENT} in ${FILE_NAME}"
  # search for a line like
  #       targetRevision: "1234" #automation:targetRevision
  # and replace 1234 with the $REPLACEMENT
  sed -i -E "s/^( *(targetRevision|newTag): )((\"?)+[A-Za-z0-9.\+-]*(\"?))( #automation:${LINE_IDENT})/\1\4${REPLACEMENT}\5\6/g" $FILE_NAME || die "having problem with replacing"
}

commitAndPush() {
  echo "--------------------------------------------------"
  echo "Commit and push to git"
  git commit -a --author="${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>" -m "Change ${LINE_IDENT} to ${REPLACEMENT}" --allow-empty || die "having problems committing"
  git push -u origin ${BRANCH_NAME} || die "having problems pushing"
}

tag() {
  echo "--------------------------------------------------"
  echo "Taging ${GIT_REPO_NAME} with tag ${TAG}"
  git tag ${TAG} ${BRANCH_NAME} || die "having problems tagging"
  git push --tags || die "having problems pushing tag"
}

branch() {
  echo "--------------------------------------------------"
  echo "Branching ${BRANCH_NAME}"
  git fetch || die "having problems fetch ${BRANCH_NAME}"
  git checkout -b ${BRANCH_NAME} || die "having problems checkout ${BRANCH_NAME}"
  git pull origin ${BRANCH_NAME} || echo "INFO: Cannot pull ${BRANCH_NAME} - probably no remote branch available"
}

generate_post_data()
{
  if [ -z ${PULL_REQUEST_URL} ]; then
    PULL_REQUEST_URL="no comment"
  fi
  PULL_REQUEST_URL="${PULL_REQUEST_URL}\\nvia: ${BITBUCKET_GIT_HTTP_ORIGIN}/addon/pipelines/home#!/results/${BITBUCKET_BUILD_NUMBER}"
  cat <<EOF
{
  "title": "Automated pull request for ${BRANCH_NAME}",
  "description": "${PULL_REQUEST_URL}",
  "fromRef": {
    "id": "refs/heads/${BRANCH_NAME}"
  },
  "toRef": {
    "id": "refs/heads/${MAIN_BRANCH_NAME}"
  },
  "locked": false
  },
}
EOF
}

pullrequest() {
  echo $(generate_post_data)
  echo "--------------------------------------------------"
  echo "Pull Request for ${BRANCH_NAME}"
  curl https://${GIT_HOST}/rest/api/1.0/projects/${GIT_PROJECT}/repos/${GIT_REPO_NAME}/pull-requests \
  --output pull-request-response.json \
  --request POST \
  --header "Authorization: Bearer ${ESC_GIT_TOKEN}" \
  --header "Content-Type: application/json" \
  --header "X-Atlassian-Token: no-check" \
  --data "$(generate_post_data)"  || die "having problems with the pull request"
  # remove trailing and leading "
  cat pull-request-response.json
  jq -r .links.self[0].href pull-request-response.json > ~/pr_href.txt
}

incompatible() {
  if [ $MULTI_APP_PARAM = true ] && [ $BRANCH_NAME_PARAM = true ]; then
    echo "Incompatible Parameters"
    echo "Your parameters: $@"
    usage
    exit 1
  fi
  if [ $MULTI_APP_PR_PARAM = true ] && [ $BRANCH_NAME_PARAM = true ]; then
    echo "Incompatible Parameters"
    echo "Your parameters: $@"
    usage
    exit 1
  fi
}

echo "--------------------------------------------------"
echo "--------------------------------------------------"
echo "Start $0"

# Loop through arguments and process them
for arg in "$@"
do
    case $arg in
        --git-host-name)
          GIT_HOST=$2
          shift # Remove argument name from processing
          shift # Remove argument value from processing
          ;;
        --git-ssh-port)
          GIT_SSH_PORT=$2
          shift # Remove argument name from processing
          shift # Remove argument value from processing
          ;;
        --git-project)
          GIT_PROJECT=$2
          shift # Remove argument name from processing
          shift # Remove argument value from processing
          ;;
        --git-repo-name)
          GIT_REPO_NAME=$2
          shift # Remove argument name from processing
          shift # Remove argument value from processing
          ;;
        --replacement)
          REPLACEMENT=$2
          shift # Remove argument name from processing
          shift # Remove argument value from processing
          ;;
        --file-name)
          FILE_NAME=$2
          shift # Remove argument name from processing
          shift # Remove argument value from processing
          ;;
        --line-identificator)
          LINE_IDENT=$2
          shift # Remove argument name from processing
          shift # Remove argument value from processing
          ;;
        --tag)
          TAG=$2
          shift # Remove argument name from processing
          shift # Remove argument value from processing
          ;;
        --branch-name)
          BRANCH_NAME=$2
          BRANCH_NAME_PARAM=true
          shift # Remove argument name from processing
          shift # Remove argument value from processing
          ;;
        --main-branch-name)
          MAIN_BRANCH_NAME=$2
          if [ $BRANCH_NAME_PARAM = false ]; then
            BRANCH_NAME=$2
          fi
          shift # Remove argument name from processing
          shift # Remove argument value from processing
          ;;
        --multi-app)
          MULTI_APP=true
          MULTI_APP_PARAM=true
          BRANCH_NAME="release/next"
          shift # Remove argument name from processing
          ;;
        --multi-app-pr)
          MULTI_APP_PR=true
          MULTI_APP_PR_PARAM=true
          BRANCH_NAME="release/next"
          shift # Remove argument name from processing
          ;;
    esac
done

incompatible
clone

if [ "$BRANCH_NAME" != "$MAIN_BRANCH_NAME" ] && [ $MULTI_APP_PR = false ]; then
  branch
fi

if [ $MULTI_APP_PR = true ]; then
  branch
fi

if [ ! -z $REPLACEMENT ] && [ ! -z $FILE_NAME ] && [ ! -z $LINE_IDENT ]; then
  replace
  commitAndPush
fi
if [ ! -z $TAG ]; then
  tag
fi


if [ "$BRANCH_NAME" != "$MAIN_BRANCH_NAME" ]; then
  if [ $MULTI_APP = false ] || [ $MULTI_APP_PR = true ]; then
    pullrequest
  fi
fi

echo "--------------------------------------------------"
echo "Done"
echo "--------------------------------------------------"
echo "--------------------------------------------------"