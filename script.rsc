# ============================================================
# DETCONNECT - GAMBLING DOMAIN BLACKLIST
# RouterOS v7
# GitHub Domain List -> MikroTik Address List
# ============================================================

:local url "https://raw.githubusercontent.com/ishall21/mikrotik-list/main/gambling-domains.txt"
:local file "gambling-domains.txt"
:local list "gambling-domains"

:log info "=========================================="
:log info "Starting Gambling Domain List Update"
:log info "=========================================="

# ------------------------------------------------------------
# Download blacklist
# ------------------------------------------------------------

:log info "Downloading gambling domain list..."

:do {

    /tool fetch \
        url=$url \
        mode=https \
        check-certificate=no \
        output=file \
        dst-path=$file

} on-error={

    :log error "ERROR: Download failed!"
    :return

}

:delay 2

# ------------------------------------------------------------
# Check downloaded file
# ------------------------------------------------------------

:if ([:len [/file find where name=$file]] = 0) do={

    :log error "ERROR: Downloaded file not found!"
    :return

}

# ------------------------------------------------------------
# Read file
# ------------------------------------------------------------

:local data [/file get $file contents]

# ------------------------------------------------------------
# Process domains
# ------------------------------------------------------------

:while ([:len $data] > 0) do={

    :local eol [:find $data "\n"]

    :if ($eol = nil) do={
        :set eol [:len $data]
    }

    :local domain [:pick $data 0 $eol]

    # Remove CR
    :if ([:len $domain] > 0) do={

        :if ([:pick $domain ([:len $domain] - 1)] = "\r") do={

            :set domain [:pick $domain 0 ([:len $domain] - 1)]

        }

    }

    # --------------------------------------------------------
    # Add domain directly to Address List
    # --------------------------------------------------------

    :if ([:len $domain] > 0) do={

        :if ([:len [/ip firewall address-list find \
            where list=$list and address=$domain]] = 0) do={

            /ip firewall address-list add \
                list=$list \
                address=$domain \
                comment=$domain

            :log info ("Added gambling domain: " . $domain)

        } else={

            :log info ("Already exists: " . $domain)

        }

    }

    # --------------------------------------------------------
    # Next line
    # --------------------------------------------------------

    :if ($eol = [:len $data]) do={

        :set data ""

    } else={

        :set data [:pick $data ($eol + 1) [:len $data]]

    }

}

# ------------------------------------------------------------
# Create firewall blocking rule
# ------------------------------------------------------------

:if ([:len [/ip firewall filter find \
    where comment="AUTO-BLOCK-GAMBLING"]] = 0) do={

    /ip firewall filter add \
        chain=forward \
        dst-address-list=$list \
        action=drop \
        comment="AUTO-BLOCK-GAMBLING"

    :log info "Firewall rule created."

}

# ------------------------------------------------------------
# Remove downloaded file
# ------------------------------------------------------------

:if ([:len [/file find where name=$file]] > 0) do={

    /file remove [/file find where name=$file]

}

:log info "Gambling domains updated successfully."