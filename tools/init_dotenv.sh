#!/usr/bin/env bash
set -e

# Environment selection menu
PS3="Please select environment (type the number): "
options=("local" "development" "staging" "production" "production_read_only")
select option in "${options[@]}"; do
    case $option in
        "local")
            IA_ENV=$option; break;;
        "development")
            IA_ENV="$option"; break;;
        "staging")
            IA_ENV="local_$option"; profile="stage"; break;;
        "production")
            IA_ENV="local_$option"; profile="e_prod"; break;;
        "production_read_only")
            # local production_read_only only requires setting
            #   the correct SDM port, which is not a secret.
            #   We do not need to escalate to a prod AWS role
            IA_ENV="local_$option"; profile="stage"; break;;
        *)
            echo "Invalid option. Try again."; continue;;
    esac
done
echo "Environment $IA_ENV has been selected"

combined_dotenv () {
  # generate env files from both service-registry.yml and chamber secrets,
  #   and combine them, preferring service-registry over secrets when
  #   the same variable name is stored in both
  # see: https://stackoverflow.com/questions/61901441
  echo 'Writing .env file'
  locals=$(mktemp)
  service-registry dotenv -e $IA_ENV -f $locals > /dev/null
  secrets=$(mktemp)
  service-registry dotenv -e $IA_ENV -f $secrets --include-secrets > /dev/null
  awk -F'=' '!a[$1]++' $locals $secrets > .env
  rm $locals $secrets
}

# Create .env file based on environment
if [ -n "$profile" ]; then
  echo "You are about to temporarily escalate AWS privileges to $profile."
  echo "This should be done judiciously."
  read -p "Are you sure you want to continue? (y to continue) " -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo # New line
    echo "Using $profile to pull config. $profile must be set in ~/.aws/config"
    AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=$profile combined_dotenv
  else
    exit 0
  fi
else
  combined_dotenv
fi

echo "Ready to export environment variables!  Run the following command in your shell:"
echo "export \$(xargs < .env)"

