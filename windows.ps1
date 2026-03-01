# GUI Apps
# UniGetUI (https://github.com/marticliment/UniGetUI)
winget install --exact --id MartiCliment.UniGetUI --source winget
# GitHub Desktop (https://desktop.github.com/)
winget install github-desktop
# Cursor (https://cursor.com)
winget install --id "Anysphere.Cursor" --exact --source winget --accept-source-agreements --disable-interactivity --silent --include-unknown --accept-package-agreements --force
# TablePlus (https://tableplus.com/)
winget install --id "TablePlus.TablePlus" --exact --source winget --accept-source-agreements --disable-interactivity --silent --include-unknown --accept-package-agreements --force

# CLI Apps
winget install --id=astral-sh.uv  -e
# TODO: find if not possible to use the git shipped with GitHub Desktop?
winget install --id Git.Git -e --source winget
