#!/usr/bin/env bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ==============================
# API CALL WRAPPER
# ==============================
read -s -p "Enter your RAPIDAPI_KEY: " actual_key
echo

local RAPIDAPI_HOST="facebook-scraper3.p.rapidapi.com"
local  RAPIDAPI_KEY="$actual_key"

# Instagram API Scraper Script
# Check for required environment variables
if [[ -z "$RAPIDAPI_HOST" || -z "$RAPIDAPI_KEY" ]]; then
    echo "Error: Missing required environment variables"
    echo "You must set both RAPIDAPI_HOST and RAPIDAPI_KEY"
    exit 1
fi

# API base URL
API_BASE="https://$RAPIDAPI_HOST"

# Helper function to make API requests
_call_api() {
    local endpoint="$1"
    local url="$API_BASE$endpoint"
    
    # Make API request with error handling
    local http_response
    http_response=$(curl --silent \
        -w "\n%{http_code}" \
        -H "x-rapidapi-host: $RAPIDAPI_HOST" \
        -H "x-rapidapi-key: $RAPIDAPI_KEY" \
        "$url")
    
    local http_status
    http_status=$(echo "$http_response" | tail -n1)
    local response_body
    response_body=$(echo "$http_response" | sed '$d')
    
    if [[ $http_status -ne 200 ]]; then
        echo "Error: API request failed (HTTP $http_status)" >&2
        echo "$response_body" >&2
        exit 1
    fi
    echo "$response_body"
}

# ==============================
# DEPENDENCY CHECK
# ==============================
check_dependencies() {
    echo -e "${YELLOW}Checking system dependencies...${NC}"
    local dependencies=("curl" "jq")

    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            echo -e "${RED}Error: '$dep' is not installed.${NC}"
            exit 1
        else
            echo -e "${GREEN}✔ $dep found${NC}"
        fi
    done
    echo -e "${MAGENTA}---------------------------------------------------------${NC}"
}

# ==============================
# PRINT HELP
# ==============================
print_help() {
    cat <<EOF
Facebook API Scraper - Function Usage

Environment Variables:
  export RAPIDAPI_HOST='facebook-scraper3.p.rapidapi.com'
  export RAPIDAPI_KEY='your-api-key'

Functions:
  get_location_info <location_name>
  search_place <query> [location_uid]
  search_video <query> [location_uid]
  search_post <query> [location_uid]
  get_profile_infos <username>
  get_page_infos <page_url>

Examples:
  get_location_info "Casablanca"
  search_place "pizza" "101891849853172"
  search_video "facebook"
  search_post "facebook"
  get_profile_infos "zuck"
  get_page_infos "https://www.facebook.com/facebook"
EOF
}

# ==============================
# FUNCTIONS
# ==============================

get_location_info() {
    local location_name="$1"
    [[ -z "$location_name" ]] && { echo "Usage: get_location_info <location_name>"; return 1; }

    local endpoint="/search/locations?query=$location_name"
    local response=$(_call_api "$endpoint") || return 1

    echo "$response" | jq -r '.results[] | {
        label,
        uid,
        city_id,
        timezone
    }'
}

search_place() {
    local place="$1"
    local location_id="$2"
    [[ -z "$place" ]] && { echo "Usage: search_place <place> [location_uid]"; return 1; }

    local endpoint="/search/places?query=$place"
    [[ -n "$location_id" ]] && endpoint="${endpoint}&location_uid=$location_id"

    local response=$(_call_api "$endpoint") || return 1

    echo "$response" | jq -r '.results[] | {
        name,
        facebook_id,
        profile_url,
        url,
        image: .image.uri,
        verified: .is_verified
    }'
}

search_video() {
    local keyword="$1"
    local location_id="$2"
    [[ -z "$keyword" ]] && { echo "Usage: search_video <keyword> [location_uid]"; return 1; }

    local endpoint="/search/videos?query=$keyword"
    [[ -n "$location_id" ]] && endpoint="${endpoint}&location_uid=$location_id"

    local response=$(_call_api "$endpoint") || return 1

    echo "$response" | jq -r '.results[] | {
        id: .video_id,
        title,
        url: .video_url,
        description,
        views_info: .time_and_views_raw,
        author_name: .author.name,
        author_id: .author.id,
        verified: .author.verification_status
    }'
}

search_post() {
    local keyword="$1"
    local location_id="$2"
    [[ -z "$keyword" ]] && { echo "Usage: search_post <keyword> [location_uid]"; return 1; }

    local endpoint="/search/posts?query=$keyword"
    [[ -n "$location_id" ]] && endpoint="${endpoint}&location_uid=$location_id"

    local response=$(_call_api "$endpoint") || return 1

    echo "$response" | jq -r '.results[] | {
        id: .post_id,
        url,
        message,
        timestamp,
        comments_count,
        reactions_count,
        reshare_count,
        reactions,
        author: {
            id: .author.id,
            name: .author.name,
            url: .author.url
        },
        image: .image.uri
    }'
}

get_profile_infos() {
    local username="$1"
    [[ -z "$username" ]] && { echo "Usage: get_profile_infos <username>"; return 1; }

    local full_url="https://web.facebook.com/$username"
    local encoded_url
    encoded_url=$(printf %s "$full_url" | jq -s -R -r @uri)

    local endpoint="/profile/details_url?url=$encoded_url"
    local response=$(_call_api "$endpoint") || return 1

    echo "$response" | jq '.profile | {
        name,
        profile_id,
        url,
        image,
        cover_image,
        gender,
        verified
    }'
}

get_page_infos() {
    local page_name="$1"

    if [[ -z "$page_name" ]]; then
        echo "Usage: get_page_infos <page_name>" >&2
        return 1
    fi

    # Build full page URL from the name
    local full_url="https://www.facebook.com/$page_name"

    # Encode the URL safely
    local encoded_url
    encoded_url=$(printf %s "$full_url" | jq -s -R -r @uri)

    # API endpoint
    local endpoint="/page/details?url=$encoded_url"

    # Call API
    local response
    response=$(_call_api "$endpoint") || return 1

    # Extract useful fields
    echo "$response" | jq '.results | {
        name,
        type,
        page_id,
        url,
        image,
        cover_image,
        likes,
        followers,
        categories,
        website,
        verified
    }'
}


# ==============================
# MAIN MENU
# ==============================
main_menu() {
    while true; do
        echo -e "\n${YELLOW}MAIN MENU${NC}"
        echo -e "${GREEN}1. Search Locations"
        echo -e "2. Search Places"
        echo -e "3. Search Videos"
        echo -e "4. Search Posts"
        echo -e "5. Get Profile Infos"
        echo -e "6. Get Page Infos"
        echo -e "7. Help"
        echo -e "8. Exit${NC}"
        echo -e "${MAGENTA}---------------------------------------------------------${NC}"

        read -p "Select an option (1-8): " choice

        case $choice in
            1) read -p "Enter location name: " loc; get_location_info "$loc" ;;
            2) read -p "Enter place/product: " place; read -p "Enter location UID (optional): " locid; search_place "$place" "$locid" ;;
            3) read -p "Enter keyword: " kw; read -p "Enter location UID (optional): " locid; search_video "$kw" "$locid" ;;
            4) read -p "Enter keyword: " kw; read -p "Enter location UID (optional): " locid; search_post "$kw" "$locid" ;;
            5) read -p "Enter username: " user; get_profile_infos "$user" ;;
            6) read -p "Enter page name: " url; get_page_infos "$url" ;;
            7) print_help ;;
            8) echo -e "${GREEN}Exiting. Thank you for using the tool!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please select 1-8.${NC}" ;;
        esac
    done
}

# ==============================
# ENTRYPOINT
# ==============================
check_dependencies
main_menu
