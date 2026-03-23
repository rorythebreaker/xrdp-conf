#!/usr/bin/env bash
# =============================================================================
#  xrdp_setup.sh — Interactive XRDP + XFCE4 Setup TUI
#  Installs and configures XRDP with XFCE4 on Ubuntu/Debian systems
# =============================================================================

# ── Color Scheme ──────────────────────────────────────────────────────────────
C_BG='\033[0;30m'
C_RESET='\033[0m'
C_BOLD='\033[1m'

C_PRIMARY='\033[38;5;75m'      # Steel blue
C_ACCENT='\033[38;5;214m'      # Amber
C_SUCCESS='\033[38;5;83m'      # Lime green
C_ERROR='\033[38;5;203m'       # Coral red
C_WARNING='\033[38;5;220m'     # Yellow
C_MUTED='\033[38;5;244m'       # Gray
C_HEADER='\033[38;5;117m'      # Light cyan
C_BORDER='\033[38;5;239m'      # Dark gray
C_WHITE='\033[38;5;255m'       # Bright white
C_DIM='\033[38;5;240m'         # Dim gray

# ── Layout ────────────────────────────────────────────────────────────────────
WIDTH=70

# ── State ─────────────────────────────────────────────────────────────────────
OPT_INSTALL_XRDP=true
OPT_ENABLE_SERVICE=true
OPT_START_SERVICE=true
OPT_CONFIGURE_FIREWALL=false
OPT_PATCH_STARTWM=true
OPT_XSESSION=true
OPT_RDP_PORT=3389
FIREWALL_CONFIRMED=false

# ── Helpers ───────────────────────────────────────────────────────────────────
repeat_char() {
    local char="$1" count="$2"
    printf '%*s' "$count" '' | tr ' ' "$char"
}

box_top() {
    echo -e "${C_BORDER}┌$(repeat_char '─' $((WIDTH-2)))┐${C_RESET}"
}

box_bot() {
    echo -e "${C_BORDER}└$(repeat_char '─' $((WIDTH-2)))┘${C_RESET}"
}

box_sep() {
    echo -e "${C_BORDER}├$(repeat_char '─' $((WIDTH-2)))┤${C_RESET}"
}

box_line() {
    local text="$1"
    local visible_len
    # Strip ANSI escape codes to measure visible length
    visible_len=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g' | wc -c)
    visible_len=$((visible_len - 1))
    local pad=$(( WIDTH - 2 - visible_len ))
    if (( pad < 0 )); then pad=0; fi
    echo -e "${C_BORDER}│${C_RESET} ${text}$(printf '%*s' "$pad" '')${C_BORDER}│${C_RESET}"
}

box_empty() {
    echo -e "${C_BORDER}│$(printf '%*s' $((WIDTH-2)) '')│${C_RESET}"
}

center_text() {
    local text="$1" color="${2:-$C_WHITE}"
    local visible_len
    visible_len=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g' | wc -c)
    visible_len=$((visible_len - 1))
    local pad_total=$(( WIDTH - 2 - visible_len ))
    local pad_left=$(( pad_total / 2 ))
    local pad_right=$(( pad_total - pad_left ))
    echo -e "${C_BORDER}│${C_RESET}$(printf '%*s' "$pad_left" '')${color}${text}${C_RESET}$(printf '%*s' "$pad_right" '')${C_BORDER}│${C_RESET}"
}

print_header() {
    clear
    echo
    box_top
    box_empty
    center_text "XRDP SETUP WIZARD" "${C_BOLD}${C_HEADER}"
    center_text "Remote Desktop Protocol for Ubuntu/Debian" "${C_MUTED}"
    box_empty
    box_bot
    echo
}

log_info()    { echo -e "  ${C_PRIMARY}[INFO]${C_RESET}  $*"; }
log_ok()      { echo -e "  ${C_SUCCESS}[ OK ]${C_RESET}  $*"; }
log_warn()    { echo -e "  ${C_WARNING}[WARN]${C_RESET}  $*"; }
log_error()   { echo -e "  ${C_ERROR}[FAIL]${C_RESET}  $*"; }
log_step()    { echo -e "\n  ${C_ACCENT}${C_BOLD}──▶${C_RESET} ${C_WHITE}${C_BOLD}$*${C_RESET}"; }
log_cmd()     { echo -e "  ${C_DIM}$ $*${C_RESET}"; }

press_enter() {
    echo
    echo -e "  ${C_MUTED}Press ${C_ACCENT}[Enter]${C_MUTED} to continue...${C_RESET}"
    read -r
}

run_cmd() {
    local desc="$1"; shift
    log_cmd "$*"
    if eval "$*" >> /tmp/xrdp_setup.log 2>&1; then
        log_ok "$desc"
        return 0
    else
        log_error "$desc"
        log_warn "See /tmp/xrdp_setup.log for details"
        return 1
    fi
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_header
        echo
        echo -e "  ${C_ERROR}${C_BOLD}Root privileges required.${C_RESET}"
        echo -e "  ${C_MUTED}Run this script with: ${C_ACCENT}sudo bash xrdp_setup.sh${C_RESET}"
        echo
        exit 1
    fi
}

check_os() {
    if ! command -v apt &>/dev/null; then
        print_header
        echo
        echo -e "  ${C_ERROR}${C_BOLD}Unsupported system.${C_RESET}"
        echo -e "  ${C_MUTED}This script requires a Debian/Ubuntu-based distro with ${C_ACCENT}apt${C_RESET}."
        echo
        exit 1
    fi
}

# ── Screens ───────────────────────────────────────────────────────────────────

screen_welcome() {
    print_header
    box_top
    box_empty
    center_text "Welcome" "${C_BOLD}${C_ACCENT}"
    box_empty
    box_line "${C_WHITE}This wizard will install and configure:${C_RESET}"
    box_empty
    box_line "  ${C_SUCCESS}●${C_RESET} ${C_WHITE}XRDP${C_RESET}   ${C_MUTED}— Remote Desktop Protocol server${C_RESET}"
    box_line "  ${C_SUCCESS}●${C_RESET} ${C_WHITE}XFCE4${C_RESET}  ${C_MUTED}— Lightweight desktop environment${C_RESET}"
    box_empty
    box_line "${C_MUTED}The following steps will be performed:${C_RESET}"
    box_line "  ${C_DIM}1.${C_RESET} ${C_MUTED}Install xrdp and xfce4 packages${C_RESET}"
    box_line "  ${C_DIM}2.${C_RESET} ${C_MUTED}Enable and start xrdp service${C_RESET}"
    box_line "  ${C_DIM}3.${C_RESET} ${C_MUTED}Patch startwm.sh (black screen fix)${C_RESET}"
    box_line "  ${C_DIM}4.${C_RESET} ${C_MUTED}Configure .xsession for XFCE4 autostart${C_RESET}"
    box_line "  ${C_DIM}5.${C_RESET} ${C_MUTED}Optionally configure UFW firewall${C_RESET}"
    box_empty
    box_bot

    echo
    echo -e "  ${C_WHITE}Start the setup? ${C_ACCENT}[Y/n]${C_RESET}: \c"
    read -r ans
    ans="${ans,,}"
    if [[ "$ans" == "n" || "$ans" == "no" ]]; then
        echo
        echo -e "  ${C_MUTED}Setup cancelled. Goodbye.${C_RESET}"
        echo
        exit 0
    fi
}

screen_options() {
    print_header
    box_top
    center_text "Configuration Options" "${C_BOLD}${C_HEADER}"
    box_sep

    # RDP Port
    box_empty
    box_line "${C_WHITE}RDP port ${C_MUTED}(default: ${C_ACCENT}3389${C_MUTED}):${C_RESET}"
    box_empty
    box_bot

    echo -e "  ${C_ACCENT}Port${C_RESET} [${C_PRIMARY}${OPT_RDP_PORT}${C_RESET}]: \c"
    read -r port_input
    if [[ -n "$port_input" ]]; then
        if [[ "$port_input" =~ ^[0-9]{1,5}$ ]] && (( port_input >= 1 && port_input <= 65535 )); then
            OPT_RDP_PORT="$port_input"
        else
            log_warn "Invalid port — keeping default ${OPT_RDP_PORT}"
            sleep 1
        fi
    fi

    # Firewall
    echo
    box_top
    box_line "${C_WHITE}Configure UFW firewall to allow port ${C_ACCENT}${OPT_RDP_PORT}/tcp${C_WHITE}?${C_RESET}"
    box_line "${C_MUTED}(Only needed if UFW is active on this system)${C_RESET}"
    box_bot

    echo -e "  ${C_ACCENT}Configure firewall?${C_RESET} [y/${C_PRIMARY}N${C_RESET}]: \c"
    read -r fw_ans
    fw_ans="${fw_ans,,}"
    if [[ "$fw_ans" == "y" || "$fw_ans" == "yes" ]]; then
        OPT_CONFIGURE_FIREWALL=true
        FIREWALL_CONFIRMED=true
    fi

    # SUDO user for .xsession
    echo
    box_top
    box_line "${C_WHITE}Username to configure ${C_ACCENT}~/.xsession${C_WHITE} for:${C_RESET}"
    box_line "${C_MUTED}(Leave blank to skip .xsession setup)${C_RESET}"
    box_bot

    echo -e "  ${C_ACCENT}Username${C_RESET} [${C_PRIMARY}${SUDO_USER:-skip}${C_RESET}]: \c"
    read -r username_input
    if [[ -n "$username_input" ]]; then
        TARGET_USER="$username_input"
    elif [[ -n "$SUDO_USER" ]]; then
        TARGET_USER="$SUDO_USER"
    else
        TARGET_USER=""
        OPT_XSESSION=false
    fi
}

screen_confirm() {
    print_header
    box_top
    center_text "Review & Confirm" "${C_BOLD}${C_HEADER}"
    box_sep
    box_empty
    box_line "  ${C_MUTED}Install xrdp + xfce4   ${C_SUCCESS}✔${C_RESET}"
    box_line "  ${C_MUTED}Enable xrdp service    ${C_SUCCESS}✔${C_RESET}"
    box_line "  ${C_MUTED}Start xrdp service     ${C_SUCCESS}✔${C_RESET}"
    box_line "  ${C_MUTED}Patch startwm.sh       ${C_SUCCESS}✔${C_RESET}"

    if [[ "$OPT_XSESSION" == true && -n "$TARGET_USER" ]]; then
        box_line "  ${C_MUTED}.xsession for user     ${C_ACCENT}${TARGET_USER}${C_RESET}"
    else
        box_line "  ${C_MUTED}.xsession setup        ${C_WARNING}skip${C_RESET}"
    fi

    if [[ "$OPT_CONFIGURE_FIREWALL" == true ]]; then
        box_line "  ${C_MUTED}UFW allow port         ${C_ACCENT}${OPT_RDP_PORT}/tcp${C_RESET}"
    else
        box_line "  ${C_MUTED}UFW firewall           ${C_MUTED}skip${C_RESET}"
    fi

    box_line "  ${C_MUTED}RDP port               ${C_ACCENT}${OPT_RDP_PORT}${C_RESET}"
    box_empty
    box_bot

    echo
    echo -e "  ${C_WHITE}Proceed with installation? ${C_ACCENT}[Y/n]${C_RESET}: \c"
    read -r ans
    ans="${ans,,}"
    if [[ "$ans" == "n" || "$ans" == "no" ]]; then
        echo
        echo -e "  ${C_MUTED}Cancelled. No changes were made.${C_RESET}"
        echo
        exit 0
    fi
}

# ── Installation Steps ────────────────────────────────────────────────────────

do_install() {
    print_header
    echo -e "  ${C_BOLD}${C_HEADER}Starting Installation${C_RESET}\n"

    # Step 1 — Update package index
    log_step "Step 1 — Updating package index"
    run_cmd "apt update" "apt-get update -qq" || true

    # Step 2 — Install xrdp and xfce4
    log_step "Step 2 — Installing xrdp and xfce4"
    run_cmd "Install xrdp" "apt-get install -y xrdp" || {
        log_error "Failed to install xrdp. Aborting."
        press_enter; exit 1
    }
    run_cmd "Install xfce4" "apt-get install -y xfce4 xfce4-goodies" || {
        log_warn "xfce4-goodies skipped — installing base xfce4 only"
        run_cmd "Install xfce4 (base)" "apt-get install -y xfce4" || {
            log_error "Failed to install xfce4. Aborting."
            press_enter; exit 1
        }
    }

    # Step 3 — Enable service
    log_step "Step 3 — Enabling xrdp service"
    run_cmd "systemctl enable xrdp" "systemctl enable xrdp"

    # Step 4 — Start service
    log_step "Step 4 — Starting xrdp service"
    run_cmd "systemctl start xrdp" "systemctl start xrdp"

    # Step 5 — Firewall
    if [[ "$OPT_CONFIGURE_FIREWALL" == true ]]; then
        log_step "Step 5 — Configuring UFW firewall"
        if command -v ufw &>/dev/null; then
            run_cmd "ufw allow ${OPT_RDP_PORT}/tcp" "ufw allow ${OPT_RDP_PORT}/tcp"
            run_cmd "ufw reload" "ufw reload"
        else
            log_warn "UFW not found — skipping firewall configuration"
        fi
    else
        log_step "Step 5 — Firewall configuration"
        log_info "Skipped (not requested)"
    fi

    # Step 6 — Patch startwm.sh (black screen fix)
    log_step "Step 6 — Patching /etc/xrdp/startwm.sh (black screen fix)"
    local startwm="/etc/xrdp/startwm.sh"
    if [[ -f "$startwm" ]]; then
        # Only patch if not already patched
        if ! grep -q "unset DBUS_SESSION_BUS_ADDRESS" "$startwm"; then
            cp "$startwm" "${startwm}.bak"
            # Insert the two unset lines before 'test -x /etc/X11/Xsession'
            sed -i '/test -x \/etc\/X11\/Xsession/i unset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR' "$startwm"
            log_ok "Patched startwm.sh (backup saved as startwm.sh.bak)"
        else
            log_info "startwm.sh already patched — skipping"
        fi
    else
        log_warn "startwm.sh not found at ${startwm} — skipping patch"
    fi

    # Step 7 — Set RDP port in xrdp.ini (if not default 3389)
    if [[ "$OPT_RDP_PORT" != "3389" ]]; then
        log_step "Step 7 — Setting RDP port to ${OPT_RDP_PORT} in xrdp.ini"
        local xrdpini="/etc/xrdp/xrdp.ini"
        if [[ -f "$xrdpini" ]]; then
            cp "$xrdpini" "${xrdpini}.bak"
            sed -i "s/^port=.*/port=${OPT_RDP_PORT}/" "$xrdpini"
            log_ok "RDP port set to ${OPT_RDP_PORT}"
        else
            log_warn "xrdp.ini not found — skipping port change"
        fi
    fi

    # Step 8 — .xsession for target user
    if [[ "$OPT_XSESSION" == true && -n "$TARGET_USER" ]]; then
        log_step "Step 8 — Configuring ~/.xsession for user: ${TARGET_USER}"
        local user_home
        user_home=$(getent passwd "$TARGET_USER" | cut -d: -f6)
        if [[ -n "$user_home" && -d "$user_home" ]]; then
            local xsession="${user_home}/.xsession"
            if ! grep -q "xfce4-session" "${xsession}" 2>/dev/null; then
                echo "xfce4-session" >> "${xsession}"
                chown "${TARGET_USER}:${TARGET_USER}" "${xsession}" 2>/dev/null || true
                log_ok "Written xfce4-session to ${xsession}"
            else
                log_info "${xsession} already contains xfce4-session — skipping"
            fi
        else
            log_warn "Home directory for '${TARGET_USER}' not found — skipping .xsession"
        fi
    else
        log_step "Step 8 — .xsession configuration"
        log_info "Skipped"
    fi

    # Step 9 — Restart xrdp to apply all changes
    log_step "Step 9 — Restarting xrdp service"
    run_cmd "systemctl restart xrdp" "systemctl restart xrdp"
}

screen_summary() {
    echo
    box_top
    center_text "Setup Complete" "${C_BOLD}${C_SUCCESS}"
    box_sep
    box_empty

    local rdp_port_label="${OPT_RDP_PORT}"
    local xsession_label
    if [[ "$OPT_XSESSION" == true && -n "$TARGET_USER" ]]; then
        xsession_label="${TARGET_USER}"
    else
        xsession_label="skipped"
    fi

    box_line "  ${C_WHITE}XRDP service status:${C_RESET}"
    local status
    status=$(systemctl is-active xrdp 2>/dev/null)
    if [[ "$status" == "active" ]]; then
        box_line "    ${C_SUCCESS}●${C_RESET} ${C_SUCCESS}running${C_RESET} ${C_MUTED}(systemctl is-active xrdp)${C_RESET}"
    else
        box_line "    ${C_ERROR}●${C_RESET} ${C_ERROR}${status}${C_RESET} ${C_MUTED}(check logs: journalctl -u xrdp)${C_RESET}"
    fi

    box_empty
    box_line "  ${C_WHITE}RDP port:${C_RESET}       ${C_ACCENT}${rdp_port_label}${C_RESET}"
    box_line "  ${C_WHITE}xsession user:${C_RESET}  ${C_ACCENT}${xsession_label}${C_RESET}"
    box_line "  ${C_WHITE}Install log:${C_RESET}    ${C_MUTED}/tmp/xrdp_setup.log${C_RESET}"
    box_empty
    box_sep
    box_empty
    box_line "  ${C_MUTED}Connect via any RDP client to:${C_RESET}"
    box_line "  ${C_ACCENT}  <your-server-ip>:${rdp_port_label}${C_RESET}"
    box_empty
    box_bot
    echo
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    check_root
    check_os
    > /tmp/xrdp_setup.log

    screen_welcome
    screen_options
    screen_confirm
    do_install
    screen_summary
}

main "$@"
