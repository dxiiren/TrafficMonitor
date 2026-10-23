# Draw a dark rounded background (background.png + background_l.png) for each Kollect skin, sized from its skin.xml.
Add-Type -AssemblyName System.Drawing
foreach ($name in 'KollectA', 'KollectB', 'KollectC') {
  $dir = Join-Path $PSScriptRoot $name
  [xml]$x = Get-Content (Join-Path $dir 'skin.xml') -Raw
  $w = [int]$x.root.layout.layout_l.width; $h = [int]$x.root.layout.layout_l.height
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
  $r = 8; $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddArc(0, 0, $r * 2, $r * 2, 180, 90); $path.AddArc($w - $r * 2 - 1, 0, $r * 2, $r * 2, 270, 90)
  $path.AddArc($w - $r * 2 - 1, $h - $r * 2 - 1, $r * 2, $r * 2, 0, 90); $path.AddArc(0, $h - $r * 2 - 1, $r * 2, $r * 2, 90, 90)
  $path.CloseFigure()
  $g.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 28, 28, 32))), $path)
  $g.DrawPath((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 60, 60, 68)), 1), $path)
  $bmp.Save((Join-Path $dir 'background.png'), [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Save((Join-Path $dir 'background_l.png'), [System.Drawing.Imaging.ImageFormat]::Png)
  "$name background ${w}x${h}"
}
