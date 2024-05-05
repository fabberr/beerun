#! /usr/bin/bash

# Simulating boolean values
true=1; false=0;

function display_help {
    echo "  NAME"
    echo "      beerun - Build and run solutions for https://judge.beecrowd.com problems implemented in C++."
    echo
    echo "  SYNOPSIS"
    echo "      beerun [COMMAND] [OPTIONS] <solution_directory>"
    echo
    echo "      beerun --help|-h"
    echo "      beerun --version|-v"
    echo
    echo "  DECRIPTION"
    echo "      Builds the solution in the specified directory and runs its test cases."
    echo "      The output is redirected to \`<solution_directory>/output.txt\`, unless specified otherwise. If the output file already exists, its contents will be truncated."
    echo
    echo "      The script may also be used to clear the results of a previous run or to create an empty project with all the required files in place."
    echo
    echo "  <solution_directory>:"
    echo "      Path to the directory containing the solution."
    echo "      The directory is expected to contain at least these files:"
    echo
    echo "          • A \`main.cpp\` source file to be compiled and linked with the following options:"
    echo "            \`/usr/bin/g++ -std=c++20 -O2 -lm -o solution main.cpp\`"
    echo
    echo "          • A \`input.txt\` text file containing the test cases that will be piped into the produced executable."
    echo "            If no such file exists in the specified directory, the solution will be built but the test cases will be skipped."
    echo
    echo "  COMMANDS"
    echo "      clean <solution_directory>"
    echo "          Cleans the specified directory by removing the files generated by a previous run."
    echo
    echo "      new <solution_directory>"
    echo "          Creates a new empty solution with the required files in the specified directory."
    echo "          If the directory exists, but is not empty, the operation will be canceled"
    echo
    echo "  OPTIONS"
    echo "      --help, -h"
    echo "          Display this help message and exit."
    echo
    echo "      --version, -v"
    echo "          Display version information"
    echo
    echo "      --test, -t"
    echo "          Only run the test cases, if a solution is already built."
    echo
    echo "      --build, -b"
    echo "          Only builds the solution, skipping the test cases."
    echo "          If --test is also present, it has no effect and the solution is still built."
    echo
    echo "      --stdout"
    echo "          If the test cases are executed, generate the output in the standard output stream."
    echo
}

function display_version {
    echo "File:           beerun.sh"
    echo "Version:        1.0.1"
    echo "Author:         https://github.com/fabberr"
    echo "Description:    Build and run solutions for https://judge.beecrowd.com problems implemented in C++."
    echo "Licence:        GPLv3 (https://www.gnu.org/licenses/gpl-3.0.txt)"
}

function clean_solution {
    solution_directory="$1";
    
    # Check if the solution directory is valid
    if [ -z "${solution_directory}" ] || [ ! -d "${solution_directory}" ]; then
        echo "[beerun::clean] Error: Invalid argument provided for <solution_directory>."
        echo "                \"${solution_directory}\" is not a valid directory."
        echo
        echo "Usage: $0 clean <solution_directory>"
        exit 1
    fi

    files=("${solution_directory}/solution" "${solution_directory}/output.txt")

    echo "[beerun] Removing files: ${files[*]}"
    rm --preserve-root=all -f "${files[@]}"
}

function new_solution {
    solution_directory="$1";

    # Check if the solution directory is valid and empty
    if [ -z "${solution_directory}" ]; then
        echo "[beerun::new] Error: Invalid argument provided for <solution_directory>."
        echo "              \"${solution_directory}\" is not a valid directory."
        echo
        echo "Usage: $0 new <solution_directory>"
        exit 1
    elif [ -d "${solution_directory}" ] && [ ! -z "$(ls -A ${solution_directory})" ]; then
        echo "[beerun::new] Error: Invalid argument provided for <solution_directory>."
        echo "              \"${solution_directory}\" is not empty. Aborting."
        exit 1
    fi

    # Setup paths
    input_path=${solution_directory}/input.txt
    source_path=${solution_directory}/main.cpp
    gitignore_path=${solution_directory}/.gitignore

    # Create solution directory
    mkdir ${solution_directory}

    # Add empty input file
    touch ${input_path}

    # Add .gitignore
    cat <<- EOF > ${gitignore_path}
	# Generated files
	output*
	solution*
	EOF

    # Add source file
    cat <<- EOF > ${source_path}
	// C++ stdlib
	#include <vector>
	#include <array>
	#include <map>
	#include <set>
	#include <unordered_map>
	#include <unordered_set>
	#include <string>
	#include <string_view>
	#include <span>
	#include <iostream>
	#include <sstream>
	#include <algorithm>
	#include <utility>
	#include <limits>
	#include <memory>
	#include <new>
	
	// C stdlib
	#include <cstddef>
	#include <cstdint>
	
	using namespace std::string_literals;
	using namespace std::string_view_literals;
	
	constexpr auto STREAMSIZE_MAX = std::numeric_limits<std::streamsize>::max();
	
	auto get_inputs(const std::size_t n) -> std::vector<std::string> {
	    std::vector<std::string> inputs{};
	    inputs.reserve(n);
	
	    for (std::size_t i = 0 ; i < n; ++i) {
	        std::string input{};
	        std::getline(std::cin, input);
	        inputs.emplace_back(std::move(input));
	    }
	
	    return inputs;
	}
	
	// https://resources.beecrowd.com/repository/UOJ_$(basename ${solution_directory}).html
	auto main() -> int {
	    std::size_t N{}; std::cin >> N;
	    std::cin.ignore(STREAMSIZE_MAX, '\n');
	
	    for (const auto& input : get_inputs(N)) {
	        std::cout << input << '\n';
	    }
	}
	EOF
}

function build_solution {
    executable_path=$1
    source_path=${solution_directory}/main.cpp
    
    if [ ! -f "${source_path}" ]; then
        echo "[beerun] Error: ${source_path} not found."
        echo "         Aborting."
        exit 1
    fi

    echo -n "[beerun] Building solution from source..."
    cpp_compiler="/usr/bin/g++"
    cpp_compiler_flags="-std=c++20 -O2 -lm"
    ${cpp_compiler} ${cpp_compiler_flags} -o ${executable_path} ${source_path}
    echo    "OK"
    echo    "    Build output saved to: ${executable_path}"
    echo
}

function run_test_cases {
    executable_path=$1; input_path=$2; output_path=$3; use_stdout=$4;

    if [ ! -f "${input_path}" ]; then
        echo "[beerun] Warning: ${input_path} not found."
        echo "         Skipping test cases."
        exit 0
    elif [ ! -f "${executable_path}" ]; then
        echo "[beerun] Error: ${executable_path} not found."
        echo "         Aborting."
        exit 1
    fi

    echo -n "[beerun] Running solutions with test cases ${input_path}..."
    if [ $true -eq ${use_stdout} ]; then
        echo
        cat "${input_path}" | "${executable_path}"
    else
        cat "${input_path}" | "${executable_path}" > "${output_path}"
        echo   "OK"
        echo    "    Test cases output saved to: ${output_path}"
    fi
}

# Parse arguments
skip_build=$false
skip_tests=$false
use_stdout=$false
while [ "$#" -gt 0 ]; do
    case $1 in
        # COMMANDS:
        clean)
            clean_solution "$2"
            exit 0
            ;;
        new)
            new_solution "$2"
            exit 0
            ;;
        
        # OPTIONS:
        --help|-h)
            display_help
            exit 0
            ;;
        --version|-v)
            display_version
            exit 0
            ;;
        
        # FLAGS:
        --stdout)
            use_stdout=$true
            ;;
        --test|-t)
            skip_build=$true
            ;;
        --build|-b)
            skip_build=$false
            skip_tests=$true
            ;;
        *)
            break
            ;;
    esac
    shift
done

# Extract positional arguments
solution_directory="$1"

# Check if the solution directory is valid
if [ -z "${solution_directory}" ] || [ ! -d "${solution_directory}" ]; then
    echo "[beerun] Error: Invalid argument provided for <solution_directory>."
    echo "         \"${solution_directory}\" is not a valid directory."
    echo
    echo "Usage: $0 [OPTIONS] <solution_directory>"
    exit 1
fi

# Setup paths
input_path=${solution_directory}/input.txt
output_path=${solution_directory}/output.txt
executable_path=${solution_directory}/solution

# Build the solution
if [ $false -eq ${skip_build} ] || [ ! -x ${executable_path} ]; then
    build_solution "${executable_path}"
fi

# Run the test cases
if [ $false -eq ${skip_tests} ]; then
    run_test_cases "${executable_path}" "${input_path}" "${output_path}" "${use_stdout}"
fi
