# /routeros/sync_user.rsc
# Create a scheduler and run the script every 5 minutes or so, remember to change your url to the google app script deployed url.
  
:local url "https://script.google.com/macros/s/xxx/exec?action=user"
:local dstFile "user_sync.txt"
:local tag "gsync"

# Download latest feed
/tool fetch url=$url dst-path=$dstFile mode=https

# Read file contents
:local content [/file get $dstFile contents]

# Track usernames found in sheet
:local activeUsers [:toarray ""]

# Split file into lines
:local lines [:toarray ""]
:local start 0

:for i from=0 to=([:len $content] - 1) do={

    :if ([:pick $content $i] = "\n") do={

        :local line [:pick $content $start $i]
        :set lines ($lines, $line)
        :set start ($i + 1)
    }
}

# Add final line if file doesn't end with newline
:if ($start < [:len $content]) do={
    :set lines ($lines, [:pick $content $start [:len $content]])
}

# Process each line
:foreach line in=$lines do={

    # Skip empty lines
    :if ([:len $line] = 0) do={ :continue }

    # Remove carriage return if present
    :if ([:pick $line ([:len $line] - 1) [:len $line]] = "\r") do={
        :set line [:pick $line 0 ([:len $line] - 1)]
    }

    # Find delimiters
    :local p1 [:find $line "|"]
    :local p2 [:find $line "|" ($p1 + 1)]

    # Validate line format
    :if (($p1 = "") || ($p2 = "")) do={
        :log warning ("Malformed line skipped: " . $line)
        :continue
    }

    # Extract fields
    :local username [:pick $line 0 $p1]
    :local password [:pick $line ($p1 + 1) $p2]
    :local status  [:pick $line ($p2 + 1) [:len $line]]

    # Track sheet users
    :set activeUsers ($activeUsers, $username)

    # Determine desired disabled state
    :local disabled false
    :if ($status = "suspended") do={
        :set disabled true
    }

    # Find PPP secret
    :local secretId [/user find where name=$username and comment=$tag]

    # Create new user if missing
    :if ([:len $secretId] = 0) do={
        
        /user add \
            name=$username \
            password=$password \
            group=full \
            disabled=$disabled \
            comment=$tag

        :log info ("User CREATED: " . $username)

    } else={

        # Read current values
        :local currentDisabled [/user get $secretId disabled]

        :local needsUpdate false

        # Compare disabled state
        :if ($currentDisabled != $disabled) do={
            :set needsUpdate true
        }

        # Update only if needed
        :if ($needsUpdate) do={

            /user set $secretId\
                disabled=$disabled \
                comment=$tag

            :log info ("User UPDATED: " . $username)

        } else={
            
            # :log info ("User UNCHANGED: " . $username)
        }
    }
}

# Disable users removed from sheet
:foreach sid in=[/user find where comment=$tag] do={

    :local uname [/user get $sid name]
    :local found false

    :foreach active in=$activeUsers do={
        :if ($active = $uname) do={
            :set found true
        }
    }

    # Disable only if user was removed and isn't already disabled
    :if (!$found) do={

        :local currentDisabled [/user get $sid disabled]

        :if (!$currentDisabled) do={

            /user set $sid disabled=yes
            :log warning ("USER DISABLED: " . $uname)

        } else={

            :log info ("USER ALREADY DISABLED: " . $uname)
            /user remove $sid
        }
    }
}
