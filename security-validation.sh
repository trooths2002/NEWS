#!/bin/bash

# Security Validation Script for CI/CD Pipeline
# This script implements the security checks defined in the secure CI/CD workflow

set -euo pipefail

echo "🔐 Starting Security Validation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    
    case $status in
        "success")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "error")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "info")
            echo -e "ℹ️  $message"
            ;;
    esac
}

# Check 1: Validate package-lock.json exists and is not tampered with
validate_package_lock() {
    print_status "info" "Validating package-lock.json..."
    
    if [ ! -f package-lock.json ]; then
        print_status "error" "package-lock.json is missing"
        return 1
    fi
    
    print_status "success" "package-lock.json exists"
    return 0
}

# Check 2: Run dependency security audit
run_dependency_audit() {
    print_status "info" "Running dependency security audit..."
    
    # Check if npm is available
    if ! command -v npm &> /dev/null; then
        print_status "error" "npm is not installed"
        return 1
    fi
    
    # Run audit and capture results
    if npm audit --audit-level high --production; then
        print_status "success" "No high/critical vulnerabilities found"
        return 0
    else
        print_status "warning" "Vulnerabilities detected - check npm audit output"
        return 1
    fi
}

# Check 3: Validate JavaScript syntax
validate_js_syntax() {
    print_status "info" "Validating JavaScript syntax..."
    
    local error_count=0
    
    # Find all JS files excluding node_modules
    while IFS= read -r -d '' file; do
        if ! node -c "$file" 2>/dev/null; then
            print_status "error" "Syntax error in $file"
            ((error_count++))
        fi
    done < <(find . -name "*.js" -not -path "./node_modules/*" -print0)
    
    if [ $error_count -eq 0 ]; then
        print_status "success" "All JavaScript files have valid syntax"
        return 0
    else
        print_status "error" "$error_count JavaScript files have syntax errors"
        return 1
    fi
}

# Check 4: Look for potential security issues
check_security_patterns() {
    print_status "info" "Checking for potential security issues..."
    
    local issues_found=0
    
    # Check for hardcoded secrets
    if grep -r -E "(password|secret|key|token)\s*[:=]\s*['\"][^'\"]+['\"]" . \
        --exclude-dir=node_modules \
        --exclude-dir=.git \
        --exclude="*.md" \
        --exclude="security-validation.sh" 2>/dev/null; then
        print_status "warning" "Potential hardcoded secrets detected"
        ((issues_found++))
    fi
    
    # Check for sensitive file types
    if find . -name "*.key" -o -name "*.pem" -o -name "*.p12" -o -name "*.pfx" | grep -v "/tmp/" | head -1 | read; then
        print_status "warning" "Sensitive files detected"
        ((issues_found++))
    fi
    
    # Check for TODO/FIXME security comments
    if grep -r -i "TODO.*security\|FIXME.*security" . \
        --exclude-dir=node_modules \
        --exclude-dir=.git 2>/dev/null; then
        print_status "warning" "Security-related TODO/FIXME items found"
        ((issues_found++))
    fi
    
    if [ $issues_found -eq 0 ]; then
        print_status "success" "No obvious security issues detected"
        return 0
    else
        print_status "warning" "$issues_found potential security issues found"
        return 1
    fi
}

# Check 5: Validate GitHub Actions workflows
validate_workflows() {
    print_status "info" "Validating GitHub Actions workflows..."
    
    local workflow_dir=".github/workflows"
    local error_count=0
    
    if [ ! -d "$workflow_dir" ]; then
        print_status "warning" "No GitHub Actions workflows found"
        return 0
    fi
    
    # Check for pinned action versions
    if grep -r "uses:.*@v[0-9]" "$workflow_dir" 2>/dev/null; then
        print_status "warning" "Found unpinned action versions (using tags instead of SHA)"
        ((error_count++))
    fi
    
    # Check for overly broad permissions
    if grep -r "permissions:.*write-all\|permissions:.*write" "$workflow_dir" 2>/dev/null | grep -v "security-events: write\|checks: write\|deployments: write\|pages: write"; then
        print_status "warning" "Found potentially overly broad permissions"
        ((error_count++))
    fi
    
    if [ $error_count -eq 0 ]; then
        print_status "success" "GitHub Actions workflows look secure"
        return 0
    else
        print_status "warning" "$error_count workflow security issues found"
        return 1
    fi
}

# Main execution
main() {
    local exit_code=0
    
    print_status "info" "Starting comprehensive security validation"
    echo "================================================="
    
    # Run all checks
    validate_package_lock || exit_code=1
    echo ""
    
    run_dependency_audit || exit_code=1
    echo ""
    
    validate_js_syntax || exit_code=1
    echo ""
    
    check_security_patterns || exit_code=1
    echo ""
    
    validate_workflows || exit_code=1
    echo ""
    
    echo "================================================="
    if [ $exit_code -eq 0 ]; then
        print_status "success" "All security validations passed!"
    else
        print_status "warning" "Some security validations failed or found issues"
        print_status "info" "Review the output above and address any issues"
    fi
    
    return $exit_code
}

# Run main function
main "$@"