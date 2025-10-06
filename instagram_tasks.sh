#!/bin/bash
read -s -p "Enter your RAPIDAPI_KEY: " actual_key
echo

local RAPIDAPI_HOST="instagram-api-fast-reliable-data-scraper.p.rapidapi.com"
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

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
instagram_main() {
    while true; do
        echo -e "\n${YELLOW}INSTAGRAM ANALYTICS${NC}"
        echo -e "${GREEN}0. Get user id"
	echo -e "1. Get User Profile"
        echo -e "2. Analyze Followers"
        echo -e "3. Analyze Following"
        echo -e "4. user media"
	echo -e "5. Get similar accounts"
        echo -e "6. Back to Main Menu${NC}"
        
        read -p "Select an option (0-6): " choice
        
        case $choice in
	    0)
		read -p "Enter Instagram username: " username
		echo "user id: "
		get_user_id_by_username $username
		;;
            1)
		read -p "Enter Instagram user_id: " user_id
                echo -e "${YELLOW}Fetching profile data for $username...${NC}"
		get_user_profile $user_id
		;;
	    2)
		read -p "Enter Instagram user_id: " user_id
                echo -e "${YELLOW}Analyzing followers for $user_id...${NC}"
		get_user_followers $user_id
		;;
	    3)
		read -p "Enter Instagram user_id: " user_id
                echo -e "${YELLOW}Analyzing following for $user_id...${NC}"
		get_user_following $user_id
		;;
	    4)
		read -p "Enter Instagram user_id: " user_id
                echo -e "${YELLOW}Analyzing content performance...${NC}"
		get_user_media $user_id
		;;
	    5)
		read -p "Enter Instagram user ID: " user_id
                echo -e "${YELLOW}Get similar accounts...${NC}"
		get_similar_accounts $user_id
		;;
            6)
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-5.${NC}"
                print_help
		sleep 1
                ;;
        esac
    done
}

# Get numeric user ID by username
get_user_id_by_username() {
    local username="$1"
    
    if [[ -z "$username" ]]; then
        echo "Usage: get_user_id_by_username <username>" >&2
        return 1
    fi
    
    local endpoint="/user_id_by_username?username=$username"
    local response
    response=$(_call_api "$endpoint")
    
    echo "$response" | jq -r '.UserID'
}

# Get user profile information
get_user_profile() {
    local user_id="$1"
    
    if [[ -z "$user_id" ]]; then
        echo "Usage: get_user_profile <user_id>" >&2
        return 1
    fi
    
    local endpoint="/profile?user_id=$user_id"
    local response
    response=$(_call_api "$endpoint")
    
    echo "$response" | jq '{
        id: .id,
        username: .username,
        full_name: .full_name,
        biography: .biography,
        follower_count: .follower_count,
        following_count: .following_count,
	category: .category,
	photo_profile: .hd_profile_pic_url_info.url
    }'
}

# Get user's following list
get_user_following() {
    local user_id="$1"
    
    if [[ -z "$user_id" ]]; then
        echo "Usage: get_user_following <user_id>" >&2
        return 1
    fi
    
    local endpoint="/following?user_id=$user_id"
    local response
    response=$(_call_api "$endpoint")
    
    echo "$response" | jq '{users: [.users[] | {username, full_name, is_private, profile_pic_url}]}'

}

# Get user's followers list
get_user_followers() {
    local user_id="$1"
    
    if [[ -z "$user_id" ]]; then
        echo "Usage: get_user_followers <user_id>" >&2
        return 1
    fi
    
    local endpoint="/followers?user_id=$user_id"
    local response
    response=$(_call_api "$endpoint")
    
    echo "$response" | jq '{users: [.users[] | {username, full_name, is_private, profile_pic_url}]}'

}

# Get similar account recommendations
get_similar_accounts() {
    local user_id="$1"
    
    if [[ -z "$user_id" ]]; then
        echo "Usage: get_similar_accounts <user_id>" >&2
        return 1
    fi
    
    local endpoint="/similar_account_recommendations?user_id=$user_id"
    local response
    response=$(_call_api "$endpoint")
    
    echo "$response" | jq '{users: [.users[] | {username, full_name, is_private, profile_pic_url}]}'

}

# Get aggregated user media
get_user_media() {
    local user_id="$1"
    
    if [[ -z "$user_id" ]]; then
        echo "Usage: get_user_media <user_id>" >&2
        return 1
    fi
    
    # Define endpoints to fetch
    declare -a endpoints=(
        "/user_post_feed?user_id=$user_id"
        "/user_reels?user_id=$user_id"
        "/user_highlights?user_id=$user_id"
        "/user_igtv_feed?user_id=$user_id"
    )
    
    # Collect all media
    local all_media="[]"
    for endpoint in "${endpoints[@]}"; do
        local response
        response=$(_call_api "$endpoint")
        all_media=$(jq -s '.[0] + (.[1] // [])' <(echo "$all_media") <(echo "$response"))
    done
    
    # Filter and format results
    echo "$all_media" | jq '[.[] | {
        id: .id,
        shortcode: .shortcode,
        media_type: .media_type,
        caption: .caption,
        media_url: .media_url,
        taken_at_timestamp: .taken_at_timestamp
    }]'
}

# Help/Usage information
print_help() {
    cat <<EOF
Instagram API Scraper - Function Usage

Environment Variables:
  export RAPIDAPI_HOST='your.api.host'
  export RAPIDAPI_KEY='your-api-key'

Functions:
1. Get user ID by username:
   get_user_id_by_username <username>

2. Get user profile:
   get_user_profile <user_id>

3. Get following list:
   get_user_following <user_id>

4. Get followers list:
   get_user_followers <user_id>

5. Get similar accounts:
   get_similar_accounts <user_id>

6. Get aggregated media:
   get_user_media <user_id>

Examples:
  get_user_id_by_username "instagram"
  get_user_profile "123456789"
  get_user_following "123456789"
EOF
}
