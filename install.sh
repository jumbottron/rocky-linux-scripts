#!/bin/bash
# HCINT_Docker_Install_Script
# Make Executable using "chmod +x install.sh"
# Execute with "sudo ./install.sh"

# Function to check command success
check_success() {
    if [ $? -ne 0 ]; then
        dialog --clear --title "Error" --msgbox "An error occurred. Please check the log for details." 10 50
        exit 1
    fi
}

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
    echo "dialog is not installed. Installing it now..."
    sudo apt-get update
    sudo apt-get install -y dialog
    check_success
fi

# Show menu using dialog
while true; do
    choice=$(dialog --clear --stdout --title "Docker Installation Script" \
        --menu "Choose an option:" 12 50 4 \
        1 "Install Docker and Docker Compose" \
        2 "Add user to docker group" \
        3 "Install Mirth Connect" \
        4 "Install Portainer" \
        5 "Exit")
        
    case $choice in
        1)
            # Check if Docker is already installed
            if command -v docker &> /dev/null; then
                dialog --clear --title "Already Installed" --msgbox "Docker is already installed." 10 50
            else
                # Install Docker
                sudo apt-get update
                sudo apt-get install -y docker.io
                check_success

                # Install Docker Compose
                if command -v docker-compose &> /dev/null; then
                    dialog --clear --title "Already Installed" --msgbox "Docker Compose is already installed." 10 50
                else
                    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                    check_success
                    sudo chmod +x /usr/local/bin/docker-compose
                fi

                # Create directories for Docker
                sudo mkdir -p /var/lib/docker
                sudo mkdir -p /etc/docker

                # Restart Docker service
                sudo systemctl restart docker
                check_success

                dialog --clear --title "Installation Complete" --msgbox "Docker and Docker Compose have been installed successfully!" 10 50
            fi
            ;;
        2)
            # Prompt user for username using dialog
            username=$(dialog --clear --inputbox "Enter username to add to docker group:" 10 50 $USER 3>&1 1>&2 2>&3)
            exitstatus=$?
            if [ $exitstatus != 0 ]; then
                dialog --clear --title "Cancelled" --msgbox "Operation cancelled." 10 50
                continue
            fi

            # Check if user is already in the docker group
            if groups $username | grep &> /dev/null '\bdocker\b'; then
                dialog --clear --title "Already Added" --msgbox "User $username is already a member of the docker group." 10 50
            else
                # Add user to docker group
                sudo usermod -aG docker $username
                check_success
                dialog --clear --title "User Added" --msgbox "User $username has been added to the docker group. Please log out and log back in for the changes to take effect." 10 50
            fi
            ;;
        3)
            # Check if Mirth is already installed
            if sudo docker ps --all --quiet --filter "name=mc" | grep -q .; then
                dialog --clear --title "Already Installed" --msgbox "Mirth is already installed." 10 50
            else
                if [ -d "michael_scripts/dockercompose/connect-docker" ]; then
                    cd michael_scripts/dockercompose/connect-docker
                    sudo docker-compose up -d
                    check_success
                    dialog --clear --title "Installation Complete" --msgbox "Mirth Connect with Postgres_DB has been installed and started successfully!" 10 50
                else
                    dialog --clear --title "Error" --msgbox "Directory michael_scripts/dockercompose/connect-docker not found." 10 50
                fi
            fi
            ;;
        4)
            # Check if Portainer is already installed
            if sudo docker ps --all --quiet --filter "name=portainer" | grep -q .; then
                dialog --clear --title "Already Installed" --msgbox "Portainer is already installed." 10 50
            else
                # Install Portainer
                sudo docker volume create portainer_data
                sudo docker run -d -p 8000:8000 -p 9000:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
                check_success
                dialog --clear --title "Installation Complete" --msgbox "Portainer has been installed successfully! Access it at http://localhost:9000" 10 50
            fi
            ;;
        5)
            # Exit
            exit
            ;;
        *)
            # Invalid option
            dialog --clear --title "Invalid Option" --msgbox "Invalid option. Please choose an option between 1 and 5." 10 50
            ;;
    esac
done
