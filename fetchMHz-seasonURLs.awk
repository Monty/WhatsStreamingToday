# Grab the season URLs from an MHz section such as:
#  <select class="js-switch-season btn-dropdown-black margin-right-medium" data-switch-season >
#      <option value="https://mhzchoice.vhx.tv/a-french-village/season:1" selected>
#        Season 1
#      </option>
#      <option value="https://mhzchoice.vhx.tv/a-french-village/season:2">
#        Season 2
#      </option>
#      <option value="https://mhzchoice.vhx.tv/a-french-village/season:3">
#        Season 3
#      </option>
#  </select>
/<select class="js-switch-season/,/<\/select>/ {
    sub (/^ */,"")
    if ($0 ~ /^<option value="/) {
        split($0,fld,"\"")
        print fld[2]
    }
}
