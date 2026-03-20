#!/bin/bash

# Supabase Audit Runner Script
# Usage: chmod +x run-audit.sh && ./run-audit.sh [project-ref]
# For local dev: ./run-audit.sh local

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_REF="${1:-local}"
SCRIPT_DIR="supabase/audit"
RESULTS_DIR="audit_results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_SUMMARY="$RESULTS_DIR/AUDIT_SUMMARY_$TIMESTAMP.txt"

# Create results directory
mkdir -p "$RESULTS_DIR"

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}  Supabase Security Audit Runner${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
echo "Project: $PROJECT_REF"
echo "Results Directory: $RESULTS_DIR"
echo "Timestamp: $TIMESTAMP"
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}✗ Supabase CLI not found. Install with:${NC}"
    echo "  npm install -g @supabase/cli"
    exit 1
fi

# Check if psql is available (for running SQL scripts)
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}⚠ psql not found in PATH${NC}"
    echo "  For remote audits, install PostgreSQL client:"
    echo "  - macOS: brew install postgresql"
    echo "  - Ubuntu: sudo apt-get install postgresql-client"
    echo "  - Windows: https://www.postgresql.org/download/windows/"
    echo ""
    echo "  Alternative: Use Supabase Studio (web UI) to run scripts"
    echo ""
fi

# Non-interactive psql defaults (safer for CI/Windows/Git Bash)
PSQL_ARGS=(
    --no-password
    --no-psqlrc
    --set ON_ERROR_STOP=1
    --pset pager=off
)

# Link to project if not local
if [ "$PROJECT_REF" != "local" ]; then
    echo -e "${YELLOW}Linking to project: $PROJECT_REF${NC}"
    supabase link --project-ref "$PROJECT_REF" || {
        echo -e "${RED}Failed to link to project. Check your credentials.${NC}"
        exit 1
    }
fi

# Start local database if needed
if [ "$PROJECT_REF" = "local" ]; then
    echo -e "${YELLOW}Starting local Supabase...${NC}"
    supabase start > /dev/null 2>&1 || {
        echo -e "${RED}Failed to start local Supabase. Run: supabase start${NC}"
        exit 1
    }
    echo -e "${GREEN}✓ Local Supabase started${NC}"
    echo ""
fi

# Function to run SQL script
run_sql_script() {
    local script_path=$1
    local output_file=$2
    
    if [ "$PROJECT_REF" = "local" ]; then
        # For local: use docker/local database connection
        psql "${PSQL_ARGS[@]}" "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f "$script_path" > "$output_file" 2>&1
    else
        # For remote: use psql if available
        if command -v psql &> /dev/null; then
            if [ -n "$SUPABASE_DB_URL" ]; then
                psql "${PSQL_ARGS[@]}" "$SUPABASE_DB_URL" -f "$script_path" > "$output_file" 2>&1
            else
                {
                    echo "SUPABASE_DB_URL is not set for remote audits."
                    echo "Set it to the Supabase session/transaction connection string (with password)."
                    echo "Example (PowerShell):"
                    echo '  $env:SUPABASE_DB_URL = "postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres?sslmode=require"'
                } > "$output_file"
                return 1
            fi
        else
            # psql not available - return error
            echo "psql not found" > "$output_file"
            return 1
        fi
    fi
}

# Array to track results
declare -a PASSED
declare -a FAILED
declare -a WARNINGS

# Run each audit script
echo -e "${BLUE}Running audit scripts...${NC}"
echo ""

for script in "$SCRIPT_DIR"/0*.sql; do
    filename=$(basename "$script")
    script_name="${filename%.sql}"
    
    echo -ne "Running ${BLUE}$script_name${NC}... "
    
    output_file="$RESULTS_DIR/${script_name}.txt"
    
    # Run the script and capture output
    if run_sql_script "$script" "$output_file"; then
        echo -e "${GREEN}✓ Done${NC}"
        
        # Check output for warnings/errors
        if grep -qi "warning\|⚠\|error\|✗" "$output_file"; then
            WARNINGS+=("$script_name")
        else
            PASSED+=("$script_name")
        fi
    else
        # Check if it failed due to setup issues or actual SQL error
        if grep -q "psql not found" "$output_file"; then
            echo -e "${YELLOW}⚠ Skipped (psql required)${NC}"
            WARNINGS+=("$script_name (psql required)")
        elif grep -q "SUPABASE_DB_URL is not set" "$output_file"; then
            echo -e "${YELLOW}⚠ Skipped (SUPABASE_DB_URL required)${NC}"
            WARNINGS+=("$script_name (SUPABASE_DB_URL required)")
        else
            echo -e "${RED}✗ Failed${NC}"
            FAILED+=("$script_name")
        fi
    fi
done

# Generate summary report
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}  Audit Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

echo "Summary saved to: $RESULTS_SUMMARY"
echo ""
echo "Audit Statistics:"
echo "  ✓ Passed:  ${#PASSED[@]}"
echo "  ⚠ Warnings: ${#WARNINGS[@]}"
echo "  ✗ Failed:  ${#FAILED[@]}"
echo ""

if [ ${#FAILED[@]} -gt 0 ]; then
    echo -e "${RED}Failed scripts:${NC}"
    for script in "${FAILED[@]}"; do
        echo "  ✗ $script"
    done
    echo ""
fi

if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo -e "${YELLOW}Scripts with warnings/issues:${NC}"
    for script in "${WARNINGS[@]}"; do
        echo "  ⚠ $script"
        echo "    → Review: $RESULTS_DIR/${script}.txt"
    done
    echo ""
fi

# Save summary to file
{
    echo "Audit Summary - $TIMESTAMP"
    echo "Project: $PROJECT_REF"
    echo ""
    echo "Status:"
    echo "  Passed:  ${#PASSED[@]}"
    echo "  Warnings: ${#WARNINGS[@]}"
    echo "  Failed:  ${#FAILED[@]}"
    echo ""
    echo "Next Steps:"
    echo "1. Review each result file in $RESULTS_DIR/"
    echo "2. Check SUPABASE_AUDIT_CHECKLIST.md for expected vs actual"
    echo "3. Create migration files for any issues found"
    echo "4. Push migrations: supabase db push"
    echo "5. Re-run audit to verify fixes"
    echo ""
} > "$RESULTS_SUMMARY"

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${GREEN}Audit complete!${NC}"
echo ""

# Show instructions based on what worked
if [ "$PROJECT_REF" != "local" ] && ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}⚠️  Missing psql - Cannot run audit against remote project${NC}"
    echo ""
    echo "To complete the audit, you have two options:"
    echo ""
    echo "  📋 Option 1: Install PostgreSQL Client (psql)"
    echo "    - macOS: brew install postgresql"
    echo "    - Ubuntu: sudo apt-get install postgresql-client"
    echo "    - Windows: https://www.postgresql.org/download/windows/"
    echo "    - Then re-run: ./supabase/audit/run-audit.sh $PROJECT_REF"
    echo ""
    echo "  🌐 Option 2: Use Supabase Studio (Web UI)"
    echo "    - Go to: https://app.supabase.com/project/$PROJECT_REF"
    echo "    - Click: SQL Editor → New Query"
    echo "    - Copy-paste each script from supabase/audit/*.sql"
    echo "    - Run and compare results with SUPABASE_AUDIT_CHECKLIST.md"
    echo ""
else
    if [ "$PROJECT_REF" != "local" ] && [ -z "$SUPABASE_DB_URL" ]; then
        echo -e "${YELLOW}⚠ SUPABASE_DB_URL is not set for remote audits${NC}"
        echo ""
        echo "PowerShell setup:"
        echo '  $env:SUPABASE_DB_URL = "postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres?sslmode=require"'
        echo "  ./supabase/audit/run-audit.sh $PROJECT_REF"
        echo ""
    fi
    echo "Next steps:"
    echo "  1. Review results: cat $RESULTS_DIR/*.txt | head -20"
    echo "  2. Check checklist: cat SUPABASE_AUDIT_CHECKLIST.md"
    echo "  3. Fix issues using MIGRATION_TEMPLATES.md"
    echo "  4. Run: supabase db push (to apply migrate migrations)"
    echo "  5. Re-run: ./supabase/audit/run-audit.sh $PROJECT_REF"
    echo ""
fi

if [ ${#FAILED[@]} -gt 0 ]; then
    exit 1
fi

exit 0