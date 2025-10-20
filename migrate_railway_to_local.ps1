# BrightBuy Database Migration Script
# Migrates Railway MySQL database to local MySQL
# Usage: .\migrate_railway_to_local.ps1

param(
    [string]$RailwayHost = "mysql-production-92d3.up.railway.app",
    [string]$RailwayPort = "3306",
    [string]$RailwayUser = "",
    [string]$RailwayPass = "",
    [string]$RailwayDB = "",
    [string]$LocalUser = "root",
    [string]$LocalPass = "",
    [string]$LocalDB = "brightbuy"
)

# ASCII Art Banner
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║   🗄️  BrightBuy Database Migration Tool   ║" -ForegroundColor Cyan
Write-Host "  ║     Railway → Local MySQL Migration        ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if MySQL is available
try {
    $mysqlVersion = mysql --version
    Write-Host "✅ MySQL found: $mysqlVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: MySQL not found in PATH" -ForegroundColor Red
    Write-Host "Please install MySQL or add it to your PATH" -ForegroundColor Yellow
    Write-Host "Example: C:\Program Files\MySQL\MySQL Server 8.0\bin" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "📋 Railway Database Configuration" -ForegroundColor Yellow
Write-Host "  Host: $RailwayHost" -ForegroundColor White

# Prompt for Railway credentials if not provided
if (-not $RailwayUser) {
    $RailwayUser = Read-Host "  Enter Railway MySQL Username"
}
if (-not $RailwayPass) {
    $RailwayPassSecure = Read-Host "  Enter Railway MySQL Password" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($RailwayPassSecure)
    $RailwayPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}
if (-not $RailwayDB) {
    $RailwayDB = Read-Host "  Enter Railway Database Name (default: railway)"
    if (-not $RailwayDB) {
        $RailwayDB = "railway"
    }
}

Write-Host ""
Write-Host "🔒 Local MySQL Configuration" -ForegroundColor Yellow
Write-Host "  User: $LocalUser" -ForegroundColor White
Write-Host "  Database: $LocalDB" -ForegroundColor White

if (-not $LocalPass) {
    $LocalPassSecure = Read-Host "  Enter Local MySQL Root Password" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($LocalPassSecure)
    $LocalPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

Write-Host ""
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 1: Test Railway Connection
Write-Host "🔌 Step 1: Testing Railway connection..." -ForegroundColor Yellow
try {
    $testQuery = "SELECT 1 as test"
    $testResult = mysql -h $RailwayHost -P $RailwayPort -u $RailwayUser -p"$RailwayPass" -e $testQuery 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Railway connection successful" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Railway connection failed" -ForegroundColor Red
        Write-Host "   Error: $testResult" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Railway connection failed: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Export from Railway
Write-Host ""
Write-Host "📤 Step 2: Exporting database from Railway..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$dumpFile = "railway_backup_$timestamp.sql"

Write-Host "   📁 Creating backup file: $dumpFile" -ForegroundColor Cyan

try {
    # Using mysqldump with proper error handling
    $dumpCmd = "mysqldump -h $RailwayHost -P $RailwayPort -u $RailwayUser -p`"$RailwayPass`" --single-transaction --quick --lock-tables=false $RailwayDB"
    
    Write-Host "   ⏳ Exporting... (this may take a minute)" -ForegroundColor Cyan
    Invoke-Expression "$dumpCmd" | Out-File -FilePath $dumpFile -Encoding UTF8
    
    if ($LASTEXITCODE -eq 0) {
        $fileSize = (Get-Item $dumpFile).Length / 1KB
        Write-Host "   ✅ Export completed: $dumpFile ($([math]::Round($fileSize, 2)) KB)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Export failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Export failed: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Test Local Connection
Write-Host ""
Write-Host "🔌 Step 3: Testing local MySQL connection..." -ForegroundColor Yellow
try {
    $testQuery = "SELECT 1 as test"
    $testResult = mysql -u $LocalUser -p"$LocalPass" -e $testQuery 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Local MySQL connection successful" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Local MySQL connection failed" -ForegroundColor Red
        Write-Host "   Error: $testResult" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Local MySQL connection failed: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Create/Recreate local database
Write-Host ""
Write-Host "🔨 Step 4: Preparing local database..." -ForegroundColor Yellow

$confirm = Read-Host "   ⚠️  This will DROP and recreate database '$LocalDB'. Continue? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "   ❌ Migration cancelled by user" -ForegroundColor Red
    exit 0
}

try {
    $createDbCmd = "DROP DATABASE IF EXISTS ``$LocalDB``; CREATE DATABASE ``$LocalDB`` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql -u $LocalUser -p"$LocalPass" -e $createDbCmd 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Local database '$LocalDB' created" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Database creation failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Database creation failed: $_" -ForegroundColor Red
    exit 1
}

# Step 5: Import to local
Write-Host ""
Write-Host "📥 Step 5: Importing to local MySQL..." -ForegroundColor Yellow
Write-Host "   ⏳ Importing... (this may take a few minutes)" -ForegroundColor Cyan

try {
    Get-Content $dumpFile | mysql -u $LocalUser -p"$LocalPass" $LocalDB 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Import completed successfully" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Import failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Import failed: $_" -ForegroundColor Red
    exit 1
}

# Step 6: Apply backorder configuration
Write-Host ""
Write-Host "🔧 Step 6: Applying backorder configuration..." -ForegroundColor Yellow
$backorderFile = "queries\05_maintenance\02_allow_backorders.sql"

if (Test-Path $backorderFile) {
    try {
        Get-Content $backorderFile | mysql -u $LocalUser -p"$LocalPass" $LocalDB 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Backorder configuration applied" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Backorder configuration may have errors (not critical)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   ⚠️  Backorder configuration skipped: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️  Backorder file not found (skipped)" -ForegroundColor Yellow
}

# Step 7: Verify migration
Write-Host ""
Write-Host "✅ Step 7: Verifying migration..." -ForegroundColor Yellow

try {
    # Count tables
    $tablesQuery = "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = '$LocalDB';"
    $tableCount = mysql -u $LocalUser -p"$LocalPass" -N -e $tablesQuery
    Write-Host "   📊 Tables found: $tableCount" -ForegroundColor Cyan
    
    # List tables
    Write-Host "   📋 Tables:" -ForegroundColor Cyan
    $tablesListQuery = "SHOW TABLES FROM ``$LocalDB``;"
    $tables = mysql -u $LocalUser -p"$LocalPass" -e $tablesListQuery
    $tables -split "`n" | Select-Object -Skip 1 | ForEach-Object {
        Write-Host "      • $_" -ForegroundColor White
    }
    
    # Count records in key tables
    Write-Host ""
    Write-Host "   📊 Data verification:" -ForegroundColor Cyan
    
    $keyTables = @("Product", "Customer", "Orders", "Inventory", "ProductVariant")
    foreach ($table in $keyTables) {
        try {
            $countQuery = "SELECT COUNT(*) FROM ``$table``;"
            $count = mysql -u $LocalUser -p"$LocalPass" $LocalDB -N -e $countQuery
            Write-Host "      • $table : $count records" -ForegroundColor White
        } catch {
            # Table might not exist
        }
    }
    
} catch {
    Write-Host "   ⚠️  Verification had some issues: $_" -ForegroundColor Yellow
}

# Final summary
Write-Host ""
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎉 Migration Completed Successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   Source     : $RailwayHost/$RailwayDB" -ForegroundColor White
Write-Host "   Destination: localhost/$LocalDB" -ForegroundColor White
Write-Host "   Backup File: $dumpFile" -ForegroundColor White
Write-Host "   Timestamp  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Update backend/.env with local database credentials" -ForegroundColor White
Write-Host "   2. Restart your backend server: cd backend && npm start" -ForegroundColor White
Write-Host "   3. Test the connection: npm run dev in frontend" -ForegroundColor White
Write-Host ""
Write-Host "💡 Tip: Keep the backup file ($dumpFile) safe!" -ForegroundColor Cyan
Write-Host ""

# Ask if user wants to update .env
$updateEnv = Read-Host "Would you like to update backend/.env file now? (yes/no)"
if ($updateEnv -eq "yes") {
    $envFile = "backend\.env"
    
    if (Test-Path $envFile) {
        # Backup existing .env
        Copy-Item $envFile "$envFile.backup_$timestamp"
        Write-Host "✅ Backed up existing .env to .env.backup_$timestamp" -ForegroundColor Green
    }
    
    # Update or create .env
    $envContent = @"
# Database Configuration - Local MySQL
DB_HOST=localhost
DB_PORT=3306
DB_USER=$LocalUser
DB_PASSWORD=$LocalPass
DB_DATABASE=$LocalDB

# JWT Secret (generate a secure random string)
JWT_SECRET=your_jwt_secret_key_here_change_this_in_production

# Server Port
PORT=5001

# For Railway deployment, uncomment and update these:
# DB_HOST=$RailwayHost
# DB_PORT=$RailwayPort
# DB_USER=$RailwayUser
# DB_PASSWORD=$RailwayPass
# DB_DATABASE=$RailwayDB
"@
    
    Set-Content -Path $envFile -Value $envContent
    Write-Host "✅ Updated backend/.env file" -ForegroundColor Green
    Write-Host "⚠️  Remember to update JWT_SECRET!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✨ All done! Happy coding! ✨" -ForegroundColor Green
Write-Host ""
