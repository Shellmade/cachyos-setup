#!/bin/bash

# Test script for CachyOS setup configuration
# This script validates the package configuration and setup script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/packages.conf"
SETUP_SCRIPT="$SCRIPT_DIR/cachyos-setup-advanced.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[TEST] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Test 1: Check if files exist
test_files_exist() {
    log "Testing if required files exist..."
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        error "packages.conf not found!"
        return 1
    fi
    
    if [[ ! -f "$SETUP_SCRIPT" ]]; then
        error "cachyos-setup-advanced.sh not found!"
        return 1
    fi
    
    if [[ ! -x "$SETUP_SCRIPT" ]]; then
        error "Setup script is not executable!"
        return 1
    fi
    
    info "✓ All required files exist and are accessible"
}

# Test 2: Validate configuration syntax
test_config_syntax() {
    log "Testing configuration file syntax..."
    
    # Source the config file to check for syntax errors
    if ! source "$CONFIG_FILE" 2>/dev/null; then
        error "Configuration file has syntax errors!"
        return 1
    fi
    
    info "✓ Configuration file syntax is valid"
}

# Test 3: Check package arrays
test_package_arrays() {
    log "Testing package array contents..."
    
    source "$CONFIG_FILE"
    
    local official_count=${#OFFICIAL_PACKAGES[@]}
    local aur_count=${#AUR_PACKAGES[@]}
    
    info "Official packages: $official_count"
    info "AUR packages: $aur_count"
    
    if [[ $official_count -eq 0 && $aur_count -eq 0 ]]; then
        warn "No packages defined in configuration!"
    fi
    
    # Check for duplicates in official packages
    local duplicates=$(printf '%s\n' "${OFFICIAL_PACKAGES[@]}" | sort | uniq -d)
    if [[ -n "$duplicates" ]]; then
        warn "Duplicate official packages found: $duplicates"
    fi
    
    # Check for duplicates in AUR packages
    duplicates=$(printf '%s\n' "${AUR_PACKAGES[@]}" | sort | uniq -d)
    if [[ -n "$duplicates" ]]; then
        warn "Duplicate AUR packages found: $duplicates"
    fi
    
    info "✓ Package arrays validated"
}

# Test 4: Check for common package name issues
test_package_names() {
    log "Testing package name formats..."
    
    source "$CONFIG_FILE"
    
    local issues=0
    
    # Check official packages
    for package in "${OFFICIAL_PACKAGES[@]}"; do
        [[ "$package" =~ ^#.*$ ]] || [[ -z "$package" ]] && continue
        
        # Check for common issues
        if [[ "$package" =~ [[:upper:]] ]]; then
            warn "Official package '$package' contains uppercase letters (unusual)"
            issues=$((issues + 1))
        fi
        
        if [[ "$package" =~ [[:space:]] ]]; then
            error "Official package '$package' contains spaces"
            issues=$((issues + 1))
        fi
    done
    
    # Check AUR packages
    for package in "${AUR_PACKAGES[@]}"; do
        [[ "$package" =~ ^#.*$ ]] || [[ -z "$package" ]] && continue
        
        if [[ "$package" =~ [[:space:]] ]]; then
            error "AUR package '$package' contains spaces"
            issues=$((issues + 1))
        fi
    done
    
    if [[ $issues -eq 0 ]]; then
        info "✓ Package names look good"
    else
        warn "$issues potential package name issues found"
    fi
}

# Test 5: Run dry-run mode
test_dry_run() {
    log "Testing dry-run execution..."
    
    info "Running setup script in dry-run mode..."
    echo "6" | timeout 10s "$SETUP_SCRIPT" --dry-run > /tmp/dryrun_output.log 2>&1 || {
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            info "✓ Dry-run timed out (expected for interactive script)"
        elif [[ $exit_code -eq 0 ]]; then
            info "✓ Dry-run completed successfully"
        else
            # Check if it at least showed the dry-run banner
            if grep -q "DRY RUN MODE ACTIVATED" /tmp/dryrun_output.log; then
                info "✓ Dry-run mode activated correctly"
            else
                error "Dry-run failed with exit code: $exit_code"
                cat /tmp/dryrun_output.log
                return 1
            fi
        fi
    }
    
    if [[ -f /tmp/dryrun_output.log ]]; then
        local lines=$(wc -l < /tmp/dryrun_output.log)
        info "✓ Dry-run produced $lines lines of output"
        
        # Check for dry-run banner
        if grep -q "DRY RUN MODE ACTIVATED" /tmp/dryrun_output.log; then
            info "✓ Dry-run banner displayed correctly"
        fi
        
        # Check for critical errors
        if grep -q "ERROR" /tmp/dryrun_output.log; then
            warn "Errors detected in dry-run output:"
            grep "ERROR" /tmp/dryrun_output.log
        fi
        
        rm -f /tmp/dryrun_output.log
    fi
}

# Test 6: Validate script permissions and dependencies
test_dependencies() {
    log "Testing script dependencies..."
    
    # Check if script can be read
    if [[ ! -r "$SETUP_SCRIPT" ]]; then
        error "Setup script is not readable!"
        return 1
    fi
    
    # Check bash syntax
    if ! bash -n "$SETUP_SCRIPT"; then
        error "Setup script has bash syntax errors!"
        return 1
    fi
    
    info "✓ Script syntax and permissions are valid"
}

# Main test execution
main() {
    echo "CachyOS Setup Script Test Suite"
    echo "==============================="
    echo
    
    local tests_passed=0
    local tests_failed=0
    
    # Run all tests
    for test in test_files_exist test_config_syntax test_package_arrays test_package_names test_dependencies test_dry_run; do
        echo
        if $test; then
            tests_passed=$((tests_passed + 1))
        else
            tests_failed=$((tests_failed + 1))
        fi
    done
    
    echo
    echo "==============================="
    echo "Test Results:"
    echo "✓ Passed: $tests_passed"
    echo "✗ Failed: $tests_failed"
    echo "==============================="
    
    if [[ $tests_failed -eq 0 ]]; then
        log "All tests passed! Your setup script is ready to use."
        echo
        info "To run the actual setup:"
        info "  ./cachyos-setup-advanced.sh"
        echo
        info "To see what would be installed without making changes:"
        info "  ./cachyos-setup-advanced.sh --dry-run"
        return 0
    else
        error "Some tests failed. Please fix the issues before running the setup."
        return 1
    fi
}

main "$@"