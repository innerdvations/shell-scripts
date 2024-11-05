# Function: newstrapi
# Purpose: This script automates the setup of a new Strapi monorepo with options to customize
# the setup process, including environment file copying, running setup scripts, and opening VS Code.
# Prerequisites:
# - Ensure the BASE_DIR and ENV_DIR variables are set according to your development environment.
# - The ENV_DIR should contain an 'ee.env' file with your license key and any additional environment variables needed.
# - The ENV_DIR should also contain a 'launch.json' file for VS Code debugging configuration.
# 
# Usage:
# - newstrapi [options] <folder_name>
# Options:
#   --no-setup    : Skip running the setup (yarn and yarn setup)
#   --no-ee       : Skip copying EE environment files
#   --no-launch   : Skip copying the VS Code launch.json file
#   --no-vscode   : Skip opening the project in VS Code
#
# Variables:
# - BASE_DIR: The base development directory where new monorepos will be created.
# - ENV_DIR: The directory containing environment files to be copied to examples.
# - REPO_URL: The Git URL for cloning the Strapi repository.
# - EXAMPLES: An array of example directories to which environment files are copied.

newstrapi() {
    # Set this to your dev directory
    local BASE_DIR=~/dev/strapi
    local ENV_DIR="$BASE_DIR/env"
    local REPO_URL="https://github.com/strapi/strapi.git"
    local EXAMPLES=("getstarted" "kitchensink-ts" "kitchensink" "experimental-dev")
    local RUN_SETUP=true
    local COPY_EE=true
    local COPY_LAUNCH=true
    local OPEN_VSCODE=true
    local FOLDER_NAME=""

    # Parse flags and folder name
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --no-setup)
                RUN_SETUP=false
                shift
                ;;
            --no-ee)
                COPY_EE=false
                shift
                ;;
            --no-launch)
                COPY_LAUNCH=false
                shift
                ;;
            --no-vscode)
                OPEN_VSCODE=false
                shift
                ;;
            -*)
                echo "Error: Unknown flag '$1'"
                return 1
                ;;
            *)
                # Set the folder name if not already set
                if [ -z "$FOLDER_NAME" ]; then
                    FOLDER_NAME=$1
                    shift
                else
                    echo "Error: Only one folder name can be provided."
                    return 1
                fi
                ;;
        esac
    done

    # Check if the folder name is provided
    if [ -z "$FOLDER_NAME" ]; then
        echo "Please provide a name for the folder."
        return 1
    fi

    if [ -d "$FOLDER_NAME" ]; then
        echo "Directory $FOLDER_NAME already exists. Choose a different name."
        return 1
    fi

    cd "$BASE_DIR" || { echo "Failed to navigate to $BASE_DIR"; return 1; }

    # Clone the repo
    git clone "$REPO_URL" "$FOLDER_NAME" || { echo "Git clone failed"; return 1; }

    # Step in
    cd "$FOLDER_NAME" || { echo "Failed to enter directory $FOLDER_NAME"; return 1; }

    # Copy over the EE envs to each example directory, if not disabled
    if [ "$COPY_EE" = true ]; then
        for example in "${EXAMPLES[@]}"; do
            if [ -d "./examples/$example" ]; then
                cp "$ENV_DIR/ee.env" "./examples/$example/.env" || echo "Warning: Failed to copy ee.env to $example"
            else
                echo "Warning: Directory ./examples/$example does not exist. Skipping."
            fi
        done
    else
        echo "Skipping copying EE envs due to --no-ee flag."
    fi

    # Copy over launch.json for debugging in vscode, if not disabled
    if [ "$COPY_LAUNCH" = true ]; then
        mkdir -p ./.vscode
        cp "$ENV_DIR/launch.json" ./.vscode/launch.json || echo "Warning: Failed to copy launch.json"
    else
        echo "Skipping copying launch.json due to --no-launch flag."
    fi

    # Run setup, if not disabled
    if [ "$RUN_SETUP" = true ]; then
        if ! yarn && yarn setup; then
            echo "Setup failed"
            return 1
        fi
    else
        echo "Skipping setup due to --no-setup flag."
    fi

    # Open VS Code with the repo, if not disabled
    if [ "$OPEN_VSCODE" = true ]; then
        code .
    else
        echo "Skipping opening VS Code due to --no-vscode flag."
    fi

    echo "Strapi monorepo setup complete!"
}
