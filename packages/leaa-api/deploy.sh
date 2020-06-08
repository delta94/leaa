#! /bin/bash

unset PLATFORM YARN_BUILD

cd "$(dirname "$0")" || exit

__DEPLOY__="./_deploy"


usage() {
  # shellcheck disable=SC2028
  echo "\n\n\n\n🔰  Usage: $0 -p test|test_docker|ecs|vercel|heroku [-i]  (e.g. sh -p test)\n\n\n\n"
  exit 2
}

set_var() {
  local arg_name=$1
  shift

  # shellcheck disable=SC2028
  echo "VAR { $arg_name: $* }"

  if [ -z "${!arg_name}" ]; then
    if [ "$arg_name" = "PLATFORM" ]; then
      if echo "$*" | grep -Eq '^test|test_docker|ecs|vercel|heroku$'; then
        eval "$arg_name=\"$*\""
      else
        usage
      fi
    fi

    if [ "$arg_name" = "YARN_BUILD" ]; then
        eval "$arg_name=\"$*\""
    fi

  else
    echo "Error: $arg_name already set"
    usage
  fi
}

platform_vercel() {
  cp -fr ./tools/deploy-config/vercel/* ${__DEPLOY__}
  cd ${__DEPLOY__} || exit

  vercel --prod -c
}

platform_ecs() {
  cd ${__DEPLOY__} || exit

  # shellcheck disable=SC2028
  echo "\n✨  Done Platform ECS\n"
}

platform_test() {
  cd ${__DEPLOY__} || exit

  yarn start
}

platform_test_docker() {
  if [ -f "${__DEPLOY__}/.env.production" ]; then
      # shellcheck disable=SC2028
      echo '\n✨  Already .env.production, Do not copy.\n'
    else
      cp -f ./.env.production ${__DEPLOY__}
  fi

  cp -f ./docker-compose.yml ${__DEPLOY__}
  cd ${__DEPLOY__} || exit

  docker-compose --env-file ./.env.production up
}

platform_heroku() {
  LOCAL_TIME=$(date "+%Y-%m-%d %H:%M:%S")

  DEPLOY_HEROKU_APP_NAME="test-leaa-api"
  DEPLOY_COMMIT="update AUTO-DEPLOY ${DEPLOY_HEROKU_APP_NAME} @ ${LOCAL_TIME}"

  cd ${__DEPLOY__} || exit
  git init
  git remote add heroku https://git.heroku.com/${DEPLOY_HEROKU_APP_NAME}.git
  git add -A
  git commit -m "${DEPLOY_COMMIT}"
  git push -f heroku master
}

# ------------------------------------------------------------------------

while getopts 'p:i?h' arg
do
  # shellcheck disable=SC2220
  case $arg in
    p) set_var PLATFORM "$OPTARG" ;;
    i) set_var YARN_BUILD ignore ;;
    h|?) usage ;;
    *) usage ;; esac
done


echo "\x1B[96m

   ___   ___  ____ ${PLATFORM}
  / _ | / _ \/  _/
 / __ |/ ___// /
/_/ |_/_/  /___/


\x1B[0m"


[ -z "$PLATFORM" ] && usage

CONFIRM_MESSAGE=$(printf "\n\n🤖 \033[1m Start Deploy <%s> ?\033[0m  (Enter/n)" "${PLATFORM}")
read -p "${CONFIRM_MESSAGE}" -n 1 -r KEY


if [ "$KEY" = "" ]; then
  # ---------
  # @ROOT-DIR
  # ---------
  if [ "$YARN_BUILD" != "ignore" ]; then
    yarn build
  fi

  #/
  if [ ! -d ${__DEPLOY__} ]; then
    mkdir -p ${__DEPLOY__}
  fi
  cp -fr ./_dist/* ${__DEPLOY__}
  cp -f ./tools/deploy-config/ecs/index.js ${__DEPLOY__}
  cp -f ./.gitignore ${__DEPLOY__}

  #/assets (copy and then delete some gen files)
  if [ ! -d ${__DEPLOY__}/src/assets ]; then
    mkdir -p ${__DEPLOY__}/src/assets
  fi
  cp -fr ./src/assets/* ${__DEPLOY__}/src/assets

  #delete some gen files
  rm -f ./src/assets/dicts/*.dict.txt
  rm -f ./src/assets/divisions/*.division.json

  #public
  if [ ! -d ${__DEPLOY__}/public ]; then
    mkdir -p ${__DEPLOY__}/public
  fi
  cp -f ./public/robots.txt ${__DEPLOY__}/public
  cp -f ./public/favicon.ico ${__DEPLOY__}/public
  cp -f ./public/get-weixin-code.html ${__DEPLOY__}/public
  cp -f ./public/version.txt ${__DEPLOY__}/public


  # -----------
  # @DEPLOY-DIR
  # -----------
  if [ -n "$PLATFORM" ]; then
    case $PLATFORM in
      test) platform_test ;;
      test_docker) platform_test_docker ;;
      ecs) platform_ecs ;;
      vercel) platform_vercel ;;
      heroku) platform_heroku ;;
      *) usage ;; esac
  fi

else
    # shellcheck disable=SC2028
    echo "\nCancel Deploy\n"
fi
