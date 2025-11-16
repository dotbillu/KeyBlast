#!/bin/zsh

WORDLIST_URL_ENGLISH="https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-no-swears.txt"
WORDLIST_FILE_ENGLISH=".keyblast_wordlist_english.txt"
WORDLIST_URL_JS="https://raw.githubusercontent.com/axios/axios/v1.x/lib/utils.js"
WORDLIST_FILE_JS=".keyblast_wordlist_js.js"
WORDLIST_URL_CPP="https://raw.githubusercontent.com/llvm/llvm-project/main/libcxx/include/string"
WORDLIST_FILE_CPP=".keyblast_wordlist_cpp.cpp"
WORDS=()
NUM_WORDS_ENGLISH=30
NUM_WORDS_CODE=40

COL_GREEN=$'\033[38;5;151m'
COL_RED=$'\033[38;5;211m'
COL_TITLE_ACCENT=$'\033[38;5;183m'
COL_PEACH=$'\033[38;5;217m'
COL_UNTYPED=$'\033[38;5;146m'
COL_RESET=$'\033[0m'
STYLE_UNDERLINE=$'\033[4m'
STYLE_NO_UNDERLINE=$'\033[24m'
STYLE_BOLD=$'\033[1m'
STYLE_NO_BOLD=$'\033[22m'
CURSOR_HIDE=$'\033[?25l'
CURSOR_SHOW=$'\033[?25h'
CLEAR_SCREEN=$'\033[2J'
CLEAR_TO_END=$'\033[0J'

TEST_TEXT=""
USER_INPUT=""
TEST_LEN=0
CURRENT_POS=0
START_TIME=0
CORRECT_CHARS=0
INCORRECT_CHARS=0
# TOTAL_PAUSE_TIME is removed
# IS_PAUSED is removed
CURRENT_TEST_MODE="English"

FINAL_WPM=""
FINAL_ACCURACY=""
FINAL_TEST_STATUS=""

function cleanup() {
    print "\n\n${COL_RESET}Restoring terminal... Goodbye!${COL_RESET}\n"
    print -n "${CURSOR_SHOW}"
    stty echo icanon
    exit 0
}

function install_dependencies() {
    local tool=$1
    print -n "${COL_PEACH}Tool '$tool' is not installed. Attempt to install? [y/N]: ${COL_RESET}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y "$tool"
        elif command -v pacman &> /dev/null; then
            sudo pacman -Syu "$tool"
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y "$tool"
        elif command -v brew &> /dev/null; then
            brew install "$tool"
        else
            print "${COL_RED}Could not determine package manager. Please install '$tool' manually.${COL_RESET}"
            exit 1
        fi
    else
        print "${COL_RED}Installation aborted. Please install '$tool' manually.${COL_RESET}"
        exit 1
    fi
}

function check_dependencies() {
    if ! command -v "bc" &> /dev/null; then
        install_dependencies "bc"
    fi
    if ! command -v "curl" &> /dev/null && ! command -v "wget" &> /dev/null; then
        print "${COL_PEACH}Neither 'curl' nor 'wget' is installed.${COL_RESET}"
        print "${COL_PEACH}Attempting to install 'curl'...${COL_RESET}"
        install_dependencies "curl"
    fi
    if ! command -v "figlet" &> /dev/null; then
        install_dependencies "figlet"
    fi
}

function download_file() {
    local file_path=$1
    local url=$2
    local language_name=$3

    if [[ -f "$file_path" ]]; then
        return 0
    fi

    print "Downloading $language_name test file... (one-time setup)"

    local status_code
    if command -v curl &> /dev/null; then
        status_code=$(curl -sI -o /dev/null -w "%{http_code}" "$url")
    elif command -v wget &> /dev/null; then
        if wget --server-response -q -O /dev/null "$url" 2>&1 | awk '/^  HTTP/{print $2}' | tail -1 | grep -q '200'; then
            status_code="200"
        else
            status_code="404"
        fi
    else
        print "${COL_RED}Error: Neither 'curl' nor 'wget' is available.${COL_RESET}"
        exit 1
    fi

    if [[ "$status_code" != "200" ]]; then
        print "${COL_RED}Error: Failed to download $language_name file. The URL returned an error (HTTP $status_code).${COL_RESET}"
        exit 1
    fi

    if command -v curl &> /dev/null; then
        curl -sLo "$file_path" "$url"
    elif command -v wget &> /dev/null; then
        wget -qO "$file_path" "$url"
    fi

    if [[ $? -ne 0 ]] || [[ ! -s "$file_path" ]]; then
        print "${COL_RED}Error: Failed to download $language_name file from $url${COL_RESET}"
        rm -f "$file_path"
        exit 1
    fi

    print "$language_name file downloaded."
}

function download_all_wordlists() {
    download_file "$WORDLIST_FILE_ENGLISH" "$WORDLIST_URL_ENGLISH" "English"
    download_file "$WORDLIST_FILE_JS" "$WORDLIST_URL_JS" "JavaScript"
    download_file "$WORDLIST_FILE_CPP" "$WORDLIST_URL_CPP" "C++"
}


function load_wordlist() {
    local file_to_load=$1
    local mode=$2

    if [[ "$mode" == "English" ]]; then
        WORDS=($(< "$file_to_load"))
    else
        local file_content=$(< "$file_to_load")
        file_content=${file_content//$'\n'/ }
        file_content=${file_content//$'\t'/ }
        
        local tokens=('=' '==' '!=' '<' '>' '<=' '>=' '+' '++' '-' '--' '*' '/' '&' '|' '!' '->' '::' ',' ';' '(' ')' '{' '}' '[' ']' ':' '?')
        for token in $tokens; do
            file_content=${file_content//${token}/ ${token} }
        done

        file_content=$(echo "$file_content" | tr -s ' ')
        
        WORDS=($=file_content)
        
        WORDS=(${WORDS:?//})
    fi
    
    if (( ${#WORDS[@]} == 0 )); then
        print "Error: Word list file '$file_to_load' is empty or could not be read after processing."
        exit 1
    fi
}

function generate_test_text() {
    TEST_TEXT=""
    USER_INPUT=""
    TEST_LEN=0
    CURRENT_POS=0
    START_TIME=0
    CORRECT_CHARS=0
    INCORRECT_CHARS=0
    # TOTAL_PAUSE_TIME reset removed
    # IS_PAUSED reset removed
    FINAL_WPM=""
    FINAL_ACCURACY=""
    FINAL_TEST_STATUS=""

    local num_words=$NUM_WORDS_ENGLISH
    if [[ "$CURRENT_TEST_MODE" != "English" ]]; then
        num_words=$NUM_WORDS_CODE
    fi
    
    for ((i = 0; i < num_words; i++)); do
        random_word=${WORDS[$((RANDOM % ${#WORDS[@]}))]}
        TEST_TEXT+="$random_word "
    done
    TEST_TEXT=${TEST_TEXT% }
    TEST_LEN=${#TEST_TEXT}
}

function render_ui() {
    print -n "\033[H"

    print "${STYLE_BOLD}Mode: ${COL_PEACH}${CURRENT_TEST_MODE}${STYLE_NO_BOLD}${COL_RESET}"
    print ""

    local current_output=""
    local line_pos=0
    local max_cols=$(tput cols)
    local global_char_index=0
    
    local words=($=TEST_TEXT) 

    for (( w = 1; w <= ${#words[@]}; w++ )); do
        local word=${words[$w]}
        local word_len=${#word}
        
        local space_needed=1
        if (( line_pos == 0 )); then
            space_needed=0
        fi

        if (( line_pos + word_len + space_needed > max_cols )); then
            current_output+="${COL_RESET}\n"
            line_pos=0
        
        elif (( w > 1 )); then
            local space_index=$((global_char_index))
            if (( space_index < CURRENT_POS )); then
                local user_char="${USER_INPUT[$((space_index + 1))]}"
                if [[ "$user_char" == " " ]]; then
                    current_output+="${STYLE_BOLD}${COL_GREEN} ${STYLE_NO_BOLD}"
                else
                    current_output+="${STYLE_BOLD}${COL_RED}${STYLE_UNDERLINE} ${STYLE_NO_UNDERLINE}${STYLE_NO_BOLD}"
                fi
            elif (( space_index == CURRENT_POS )); then
                current_output+="${COL_PEACH}${STYLE_UNDERLINE} ${STYLE_NO_UNDERLINE}"
            else
                current_output+="${COL_UNTYPED} "
            fi
            
            line_pos=$((line_pos + 1))
            global_char_index=$((global_char_index + 1))
        fi

        for (( c = 1; c <= word_len; c++ )); do
            local char_index=$((global_char_index + c - 1))
            local target_char="${word[$c]}"
            local char_output=""
            
            if (( char_index < CURRENT_POS )); then
                local bold_start="${STYLE_BOLD}"
                local bold_end="${STYLE_NO_BOLD}"
                local user_char="${USER_INPUT[$((char_index + 1))]}"
                
                if [[ "$user_char" == "$target_char" ]]; then
                    char_output="${bold_start}${COL_GREEN}${target_char}${bold_end}"
                else
                    char_output="${bold_start}${COL_RED}${target_char}${bold_end}"
                fi
            elif (( char_index == CURRENT_POS )); then
                char_output="${COL_PEACH}${STYLE_UNDERLINE}${target_char}${STYLE_NO_UNDERLINE}"
            else
                char_output="${COL_UNTYPED}${target_char}"
            fi
            current_output+="$char_output"
        done
        
        line_pos=$((line_pos + word_len))
        global_char_index=$((global_char_index + word_len))
    done
    
    if (( CURRENT_POS == TEST_LEN )); then
         current_output+="${COL_PEACH}${STYLE_UNDERLINE} ${STYLE_NO_UNDERLINE}"
    fi

    print -n "${current_output}${COL_RESET}${CLEAR_TO_END}"

    print "\n\n"
    local wpm=0
    local accuracy=0
    local total_typed=$((CORRECT_CHARS + INCORRECT_CHARS))
    
    # Pause logic removed here, assuming active time is total elapsed time
    if ((START_TIME > 0)); then
        local now=$(date +%s)
        local elapsed_active=$(echo "$now - $START_TIME" | bc)
        
        if (($(echo "$elapsed_active > 0" | bc -l))); then
            local elapsed_min=$(echo "$elapsed_active / 60" | bc -l)
            
            if (($(echo "$elapsed_min > 0" | bc -l))); then
                if ((CORRECT_CHARS > 0)); then
                    wpm=$(echo "($CORRECT_CHARS / 5) / $elapsed_min" | bc -l)
                fi
            fi
        fi
        
        if ((total_typed > 0)); then
            accuracy=$(echo "($CORRECT_CHARS / $total_typed) * 100" | bc -l)
        fi
    fi

    printf "WPM: %s%.0f%s\n" "${STYLE_BOLD}${COL_PEACH}" $wpm "${COL_RESET}${STYLE_NO_BOLD}"
    printf "Accuracy: %s%.1f%%%s\n" "${STYLE_BOLD}${COL_PEACH}" $accuracy "${COL_RESET}${STYLE_NO_BOLD}"
    printf "[Correct: %s%d%s | Incorrect: %s%d%s | Total: %d/%d]\n" "${COL_GREEN}" $CORRECT_CHARS "${COL_RESET}" "${COL_RED}" $INCORRECT_CHARS "${COL_RESET}" $CURRENT_POS $TEST_LEN
    print "\n${COL_UNTYPED}[Esc] Cancel Test${COL_RESET}"
}

function update_stats() {
    CORRECT_CHARS=0
    INCORRECT_CHARS=0
    for ((i = 0; i < CURRENT_POS; i++)); do
        if [[ "${USER_INPUT[$((i + 1))]}" == "${TEST_TEXT[$((i + 1))]}" ]]; then
            CORRECT_CHARS=$((CORRECT_CHARS + 1))
        else
            INCORRECT_CHARS=$((INCORRECT_CHARS + 1))
        fi
    done
}

function run_test() {
    local file_to_load=""
    case $CURRENT_TEST_MODE in
        "JavaScript")
            file_to_load=$WORDLIST_FILE_JS
            ;;
        "C++")
            file_to_load=$WORDLIST_FILE_CPP
            ;;
        *)
            CURRENT_TEST_MODE="English"
            file_to_load=$WORDLIST_FILE_ENGLISH
            ;;
    esac
    
    load_wordlist "$file_to_load" "$CURRENT_TEST_MODE"
    generate_test_text
    
    print -n "$CLEAR_SCREEN\033[H"
    render_ui
    print "\n\nPress any key to start..."
    IFS= read -rsn1

    START_TIME=$(date +%s)
    FINAL_TEST_STATUS="Completed"
    
    render_ui

    while true; do
        
        IFS= read -rsk1 char
        
        local needs_full_render=false
        
        # Pause logic removed. 'Tab' key is no longer handled.
        
        if [[ $char == $'\x1b' ]]; then
            FINAL_TEST_STATUS="Canceled"
            break
        
        elif [[ $char == $'\x7f' || $char == $'\b' ]]; then
            if ((CURRENT_POS > 0)); then
                CURRENT_POS=$((CURRENT_POS - 1))
                USER_INPUT=${USER_INPUT[1,$CURRENT_POS]}
                needs_full_render=true 
            fi
            
        elif [[ -n "$char" ]]; then
            if ((CURRENT_POS < TEST_LEN)); then
                USER_INPUT+="$char"
                CURRENT_POS=$((CURRENT_POS + 1))
                needs_full_render=true 
            fi
        fi
        
        update_stats

        if $needs_full_render; then
            render_ui 
        fi

        if ((CURRENT_POS == TEST_LEN)); then
            break
        fi
    done

    if [[ "$FINAL_TEST_STATUS" == "Completed" ]]; then
        local wpm=0
        local accuracy=0
        local total_typed=$((CORRECT_CHARS + INCORRECT_CHARS))
        
        local now=$(date +%s)
        local elapsed_active=$(echo "$now - $START_TIME" | bc)
        
        if (($(echo "$elapsed_active > 0" | bc -l))); then
            local elapsed_min=$(echo "$elapsed_active / 60" | bc -l)

            if (($(echo "$elapsed_min > 0" | bc -l))); then
                if ((CORRECT_CHARS > 0)); then
                    wpm=$(echo "($CORRECT_CHARS / 5) / $elapsed_min" | bc -l)
                fi
            fi
        fi
        
        if ((total_typed > 0)); then
            accuracy=$(echo "($CORRECT_CHARS / $total_typed) * 100" | bc -l)
        fi

        FINAL_WPM=$(printf "%.0f" $wpm)
        FINAL_ACCURACY=$(printf "%.1f" $accuracy)
    else
        FINAL_WPM="N/A"
        FINAL_ACCURACY="N/A"
    fi
}

function show_language_menu() {
    print -n "$CLEAR_SCREEN\033[H"
    
    print "${STYLE_BOLD}${COL_TITLE_ACCENT}"
    figlet -w "$(tput cols)" -c "KeyBlast"
    print "${STYLE_NO_BOLD}${COL_RESET}"

    print "\n\n      Select a Test Mode:\n"
    print "      ${STYLE_BOLD}[1]${STYLE_NO_BOLD} -  English (Alphabet)"
    print "      ${STYLE_BOLD}[2]${STYLE_NO_BOLD} -  JavaScript (Syntax-focused)"
    print "      ${STYLE_BOLD}[3]${STYLE_NO_BOLD} -  C++ (Syntax-focused)"
    print "\n      ${STYLE_BOLD}[b]${STYLE_NO_BOLD} -  Back to Main Menu"
    print "\n\n"

    while true; do
        IFS= read -rsk1 key
        case $key in
            "1")
                CURRENT_TEST_MODE="English"
                run_test
                return
                ;;
            "2")
                CURRENT_TEST_MODE="JavaScript"
                run_test
                return
                ;;
            "3")
                CURRENT_TEST_MODE="C++"
                run_test
                return
                ;;
            "b" | $'\x1b')
                return
                ;;
        esac
    done
}


function show_main_menu_ui() {
    print -n "$CLEAR_SCREEN\033[H"
    
    print "${STYLE_BOLD}${COL_TITLE_ACCENT}"
    figlet -w "$(tput cols)" -c "KeyBlast"
    print "${STYLE_NO_BOLD}${COL_RESET}"
    
    print "      Welcome to the command-line typing test!\n\n"
    
    print "      ${STYLE_BOLD}[Enter]${STYLE_NO_BOLD}   -  Start New Test"
    print "      ${STYLE_BOLD}[Ctrl+C]${STYLE_NO_BOLD} -  Exit"
    print "\n\n"
}

function show_summary_screen() {
    print -n "$CLEAR_SCREEN\033[H"

    if [[ "$FINAL_TEST_STATUS" == "Completed" ]]; then
        print "${STYLE_BOLD}${COL_GREEN}"
        figlet -w "$(tput cols)" -c "Test Complete"
        print "${STYLE_NO_BOLD}${COL_RESET}"

        print "\n\n"
        print "      ${STYLE_BOLD}Mode: ${COL_TITLE_ACCENT}${CURRENT_TEST_MODE}${STYLE_NO_BOLD}"
        print "      ${STYLE_BOLD}WPM: ${COL_GREEN}${FINAL_WPM}${STYLE_NO_BOLD}"
        print "      ${STYLE_BOLD}Accuracy: ${COL_GREEN}${FINAL_ACCURACY}%%${STYLE_NO_BOLD}"
        
    else
        print "${STYLE_BOLD}${COL_RED}"
        figlet -w "$(tput cols)" -c "Test Canceled"
        print "${STYLE_NO_BOLD}${COL_RESET}"

        print "\n\n"
        print "      ${STYLE_BOLD}Mode: ${COL_TITLE_ACCENT}${CURRENT_TEST_MODE}${STYLE_NO_BOLD}"
        print "      ${STYLE_BOLD}WPM: ${COL_RED}${FINAL_WPM}${STYLE_NO_BOLD}"
        print "      ${STYLE_BOLD}Accuracy: ${COL_RED}${FINAL_ACCURACY}%%${STYLE_NO_BOLD}"
    fi
    
    print "\n\n      Press any key to return to the main menu..."
}

function check_terminal_size() {
    local min_cols=80
    local min_lines=24
    
    local cols=$(tput cols)
    local lines=$(tput lines)

    while (( cols < min_cols || lines < min_lines )); do
        print -n "$CLEAR_SCREEN\033[H"
        print "${COL_PEACH}Your terminal is too small ($cols x $lines).${COL_RESET}"
        print "Please resize to at least ${min_cols} x ${min_lines}."
        print "(Fullscreen is recommended)\n"
        print "Press any key to re-check..."
        
        IFS= read -rsk1
        cols=$(tput cols)
        lines=$(tput lines)
    done
}

check_dependencies
download_all_wordlists

trap cleanup SIGINT SIGTERM
stty -echo -icanon
echo -n "${CURSOR_HIDE}"

while true; do
    check_terminal_size
    
    if [[ -n "$FINAL_WPM" ]]; then
        show_summary_screen
        IFS= read -rsk1
        FINAL_WPM=""
    else
        show_main_menu_ui
        IFS= read -rsk1 key
        
        if [[ "$key" == $'\n' ]]; then
            show_language_menu
        fi
    fi
done
