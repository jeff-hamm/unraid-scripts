#!/usr/bin/env zsh
# Shared utility parser for scripts and functions
# Extracts @desc comments from files
#
# Output format: Each line is "name\tdescription" (tab-separated)
# Consumers should read line-by-line and split on the first tab.

# Parse @desc from script files in .local/bin
# Outputs: name<TAB>description per line
parse_script_descriptions() {
    local PHOME="${PHOME:-$HOME}"
    local script name desc line_num in_desc line continuation
    
    for script in "$PHOME/.local/bin/"*(N-*); do
        [[ -f "$script" ]] || continue
        name="${script:t}"  # basename
        
        # Read first few lines looking for @desc after shebang
        desc=""
        line_num=0
        in_desc=false
        while IFS= read -r line && (( line_num++ < 20 )); do
            # Skip shebang
            [[ "$line" == "#!"* ]] && continue
            # Look for @desc (single or multiline)
            if [[ "$line" == *"# @desc "* ]]; then
                desc="${line#*@desc }"
                in_desc=true
            # Continue multiline @desc
            elif [[ "$in_desc" == true && "$line" == "#   "* ]]; then
                continuation="${line#\#   }"
                desc="$desc $continuation"
            elif [[ "$in_desc" == true && "$line" == "# "* && "$line" != "# @"* ]]; then
                continuation="${line#\# }"
                desc="$desc $continuation"
            # Stop at first non-comment/non-empty line
            elif [[ "$in_desc" == true && -n "$line" && "$line" != "#"* ]]; then
                break
            elif [[ -z "$line" ]]; then
                continue
            elif [[ "$line" != "#"* ]]; then
                break
            fi
        done < "$script"
        
        # Output tab-separated: name<TAB>description
        printf '%s\t%s\n' "$name" "${desc:-No description}"
    done
}

# Parse @desc from function definitions in a file
# Outputs: name<TAB>description per line
parse_function_descriptions() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    
    local line func_name desc="" in_desc=false continuation
    
    while IFS= read -r line; do
        # Look for start of @desc
        if [[ "$line" == *"# @desc "* ]]; then
            desc="${line#*@desc }"
            in_desc=true
        # Continue multiline @desc
        elif [[ "$in_desc" == true && "$line" == "#   "* ]]; then
            continuation="${line#\#   }"
            desc="$desc $continuation"
        elif [[ "$in_desc" == true && "$line" == "# "* && "$line" != "# @"* ]]; then
            continuation="${line#\# }"
            desc="$desc $continuation"
        # Look for function definitions - match "name() {" pattern
        elif [[ "$line" == [a-zA-Z_-]*"()"* ]]; then
            func_name="${line%%\(\)*}"
            func_name="${func_name##[[:space:]]}"
            if [[ -n "$desc" && -n "$func_name" ]]; then
                printf '%s\t%s\n' "$func_name" "$desc"
            fi
            desc=""
            in_desc=false
        # Any other non-comment, non-empty line ends multiline desc
        elif [[ "$in_desc" == true && -n "$line" && "$line" != "#"* ]]; then
            in_desc=false
        fi
    done < "$file"
}

# Parse all function files in a directory
# Outputs: name<TAB>description per line (all functions combined)
parse_all_function_descriptions() {
    local dir="${1:-${PHOME:-$HOME}/.zsh/functions}"
    local file
    
    [[ -d "$dir" ]] || return 0
    
    for file in "$dir"/*.zsh(N); do
        [[ -f "$file" ]] || continue
        parse_function_descriptions "$file"
    done
}
