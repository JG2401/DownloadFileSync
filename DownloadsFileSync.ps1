$sourcePath = "C:\Users\jonas\Downloads"
$destinationPath = "\\synology-ds720\DS720\Software"
$fileExtensions = @("exe", "msi", "iso", "img")
$pattern = "[A-Za-z]+"
$timeSpan = New-TimeSpan -Seconds 600

while ($true) {
    $now = Get-Date
    $counter = 0
    
    $files = Get-ChildItem -Path $sourcePath -File | Where-Object {
        $_.LastWriteTime -gt $now.Subtract($timeSpan) -and
        $fileExtensions -contains $_.Extension.TrimStart('.').ToLower()
    }

    foreach ($file in $files) {        
        $extensionFolder = Join-Path -Path $destinationPath -ChildPath $file.Extension.ToLower()
        if(-not (Test-Path -Path $extensionFolder))
        {
            New-Item -ItemType Directory -Path $extensionFolder
        }
        
        if ($file.BaseName -match $pattern) 
        {            
            $subfolder = [regex]::Match($file.Name, $pattern).Value
            $destFolder = Join-Path -Path $extensionFolder -ChildPath $subfolder

            if (-not (Test-Path -Path $destFolder)) 
            {
                New-Item -ItemType Directory -Path $destFolder
            }            
        }
        else
        {
            $destFolder = $extensionFolder
        }
        
        Copy-Item -Path $file.FullName -Destination "$($destFolder)\$($now.ToString("yyyy-MM-dd"))_$($file.Name)" -Force
        $counter++
    }

    
    #NOTIFICATION
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)

    $toastXml = [xml] $template.GetXml()
    $toastXml.GetElementsByTagName("text").Item(0).AppendChild($toastXml.CreateTextNode("Files synchronized")) > $null
    $toastXml.GetElementsByTagName("text").Item(1).AppendChild($toastXml.CreateTextNode("$($counter) of $($files.Count)")) > $null

    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml($toastXml.OuterXml)

    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
    $toast.Tag = "DownloadsFileSync"
    $toast.Group = "DownloadsFileSync"
    $toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("DownloadsFileSync")
    $notifier.Show($toast);


    #START-SLEEP
    Start-Sleep -Seconds $timeSpan.TotalSeconds
}