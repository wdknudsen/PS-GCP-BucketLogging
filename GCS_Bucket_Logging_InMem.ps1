# Configures logging on buckets that don't have logging enabled

# set output encoding to prevent crash when enabling logging
[Console]::OutputEncoding = [System.Text.Encoding]::Default

# sets utf-8 encoding
#chcp 65001

# resets project variables
$projects = ""
$projcount = 0
$totalproj = 0

# sets prod and non-prod buckets to store the logs in
$prdbucket = "Prod"
$npdbucket = "NonProd"

# assigns project list and count to variables 
$loadprojects = gcloud projects list --format="csv(project_id)"
$projects = $loadprojects | Where-Object { $_ -ne "project_id"}
$totalproj = $projects.count


$projects | ForEach-Object {
    $projcount++
    $proj = $_
    $projlength = $_.length
    
    "Project $($projcount) of $($totalproj) Being Processed: $($_)"
    
    # filters out monitoring and out-of-scope projects based on last letter of bucket name
    if ($_.substring($_.length -1,1) -in ("t","d","p") -AND $_ -notlike "*monitoring*") {
    
        # assigns buckets and count to variables
        $bucket = gsutil ls -p $_
        $totalbuc = $bucket.count

        # checks if logging is enable and configures logging if not enabled for projects with buckets
        if ($bucket.count -gt 0) {
            $buccount = 0

            $bucket | ForEach-Object {
                $buccount++
                $bucketlength = $_.length
                $shortbucket = $_.substring(5, $bucketlength -6)
                                
                "   Bucket $($buccount) of $($totalbuc) Being Processed: $($_)"
                $loggingstatus = gsutil logging get $_

                #Configures logging if not enabled, displays configuration if enabled
                if ($loggingstatus.substring(0,1) -ne "{") {
                    if ($proj.substring($projlength -1,1) -in ("t","d")) {
                        "       Enabling logging on $($_)"
                        gsutil -q logging set on -b gs://$npdbucket -o $shortbucket/$shortbucket $_
                        "       Configuration: $(gsutil logging get $_)"
                    } elseif ($proj.substring($projlength -1,1) -eq "p") {
                        "       Enabling logging on $($_)"
                        gsutil -q logging set on -b gs://$prdbucket -o $shortbucket/$shortbucket $_
                        "       Configuration: $(gsutil logging get $_)"
                    }
                } else {
                    "       Bucket Previously Configured: $($loggingstatus)"
                }
            }
        } else {
            "   $($proj) contains no buckets."
        }
    # trap for monitoring projects
    } elseif ($_ -like "*monitoring*") {
        "   Monitoring Project - Logging Not Enabled"
    # trap for out-of-scope projects
    } else {
        "   ATTENTION: Project is outside the scope of this script, please review."
    } 
    "`n"
}