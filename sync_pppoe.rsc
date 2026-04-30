# /routeros/sync_pppoe.rsc
# Remember to change the url

:local url "https://script.google.com/macros/s/xxx/exec?action=pppoe"
:local dstFile "pppoe_sync.txt"
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
    :local p3 [:find $line "|" ($p2 + 1)]

    # Validate line format
    :if (($p1 = "") || ($p2 = "") || ($p3 = "")) do={
        :log warning ("Malformed line skipped: " . $line)
        :continue
    }

    # Extract fields
    :local username [:pick $line 0 $p1]
    :local password [:pick $line ($p1 + 1) $p2]
    :local profile  [:pick $line ($p2 + 1) $p3]
    :local status   [:pick $line ($p3 + 1) [:len $line]]

    # Track sheet users
    :set activeUsers ($activeUsers, $username)

    # Determine desired disabled state
    :local disabled false
    :if ($status = "suspended") do={
        :set disabled true
    }

    # Find PPP secret
    :local secretId [/ppp secret find where name=$username and comment=$tag]

    # Create new user if missing
    :if ([:len $secretId] = 0) do={

        /ppp secret add \
            name=$username \
            password=$password \
            profile=$profile \
            disabled=$disabled \
            comment=$tag

        :log info ("PPP CREATED: " . $username)

    } else={

        # Read current values
        :local currentPassword [/ppp secret get $secretId password]
        :local currentProfile  [/ppp secret get $secretId profile]
        :local currentDisabled [/ppp secret get $secretId disabled]

        :local needsUpdate false

        # Compare password
        :if ($currentPassword != $password) do={
            :set needsUpdate true
        }

        # Compare profile
        :if ($currentProfile != $profile) do={
            :set needsUpdate true
        }

        # Compare disabled state
        :if ($currentDisabled != $disabled) do={
            :set needsUpdate true
        }

        # Update only if needed
        :if ($needsUpdate) do={

            /ppp secret set $secretId \
                password=$password \
                profile=$profile \
                disabled=$disabled

            :log info ("PPP UPDATED: " . $username)

        } else={

            # :log info ("PPP UNCHANGED: " . $username)
        }
    }
}

# Disable users removed from sheet
:foreach sid in=[/ppp secret find where comment=$tag] do={

    :local uname [/ppp secret get $sid name]
    :local found false

    :foreach active in=$activeUsers do={
        :if ($active = $uname) do={
            :set found true
        }
    }

    # Disable only if user was removed and isn't already disabled
    :if (!$found) do={

        :local currentDisabled [/ppp secret get $sid disabled]

        :if (!$currentDisabled) do={

            /ppp secret set $sid disabled=yes
            /ppp secret remove $sid
            :log warning ("PPP DISABLED: " . $uname)

        } else={

            :log info ("PPP ALREADY DISABLED: " . $uname)
        }
    }
}
