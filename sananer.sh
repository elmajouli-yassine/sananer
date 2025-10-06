#!/bin/bash

# Sananer - Social Media Analytics Tool
# Version: 1.0
# Author: El majouli yassine

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner display
print_banner() {
    clear
    echo -e "${YELLOW}"
    echo -e "  ███████╗ █████╗ ███╗   ██╗ █████╗ ███╗   ██╗███████╗██████╗ "
    echo -e "  ██╔════╝██╔══██╗████╗  ██║██╔══██╗████╗  ██║██╔════╝██╔══██╗"
    echo -e "  ███████╗███████║██╔██╗ ██║███████║██╔██╗ ██║█████╗  ██████╔╝"
    echo -e "  ╚════██║██╔══██║██║╚██╗██║██╔══██║██║╚██╗██║██╔══╝  ██╔══██╗"
    echo -e "  ███████║██║  ██║██║ ╚████║██║  ██║██║ ╚████║███████╗██║  ██║"
    echo -e "  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝${NC}"
    echo -e "${BLUE}                   Social Media Analytics Toolkit${NC}"
    echo -e "${MAGENTA}---------------------------------------------------------${NC}"
}

# Tool definition and educational purpose
print_intro() {
    echo -e "${CYAN}"
    echo -e "EDUCATIONAL PURPOSE:"
    echo -e "Sananer is designed for educational purposes to demonstrate:"
    echo -e " - API integration concepts with social media platforms"
    echo -e " - Ethical data collection practices"
    echo -e " - Data analysis fundamentals"
    echo -e " - Privacy-aware social media analytics"
    echo -e ""
    echo -e "This tool connects to official APIs through RapidAPI services to"
    echo -e "collect publicly available information while respecting platform"
    echo -e "terms of service. All collected data is for analysis demonstration"
    echo -e "only and should not be stored or used commercially."
    echo -e "${NC}"
    echo -e "${MAGENTA}---------------------------------------------------------${NC}"
}

check_dependencies() {
    echo -e "${YELLOW}Checking system dependencies...${NC}"

    local dependencies=("curl" "jq")

    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            echo -e "${RED}Error: '$dep' is not installed or not in PATH.${NC}"
            echo -e "Please install it before running this tool."
            exit 1
        else
            echo -e "${GREEN}✔ $dep found${NC}"
        fi
    done

    echo -e "${MAGENTA}---------------------------------------------------------${NC}"
    echo -e "${GREEN}All dependencies satisfied. Continuing...${NC}"
    sleep 1
}

# Main menu with platform selection
main_menu() {
    while true; do
        echo -e "\n${YELLOW}MAIN MENU${NC}"
        echo -e "${GREEN}1. Instagram Analytics"
        echo -e "2. Facebook Insights"
        echo -e "3. LinkedIn Professional Data"
        echo -e "4. Twitter (X) Metrics"
        echo -e "5. Exit${NC}"
        echo -e "${MAGENTA}---------------------------------------------------------${NC}"
        
        read -p "Select a platform (1-5): " choice
        
        case $choice in
            1)
                source instagram_tasks.sh
                instagram_main
                ;;
            2)
                source facebook_tasks.sh
                facebook_main
                ;;
            3)
                source linkedin_tasks.sh
                linkedin_main
                ;;
            4)
                echo -e "${YELLOW}Twitter module coming soon!${NC}"
                sleep 2
                ;;
            5)
                echo -e "${GREEN}Exiting Sananer. Thank you for using our tool!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-5.${NC}"
                sleep 1
                ;;
        esac
    done
}
print_banner
print_intro
check_dependencies
main_menu
