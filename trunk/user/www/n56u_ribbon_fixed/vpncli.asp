<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - VPN Client Subscription</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">

<link rel="shortcut icon" href="images/favicon.ico">
<link rel="icon" href="images/favicon.png">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/engage.itoggle.css">

<script type="text/javascript" src="/jquery.js"></script>
<script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/bootstrap/js/engage.itoggle.min.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/itoggle.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script>
var $j = jQuery.noConflict();

$j(document).ready(function() {
    init_itoggle('vpnc_enable', change_vpnc_enabled);
});

</script>
<script>

lan_ipaddr_x = '<% nvram_get_x("", "lan_ipaddr"); %>';
lan_netmask_x = '<% nvram_get_x("", "lan_netmask"); %>';
vpnc_state_last = '<% nvram_get_x("", "vpnc_state_t"); %>';

<% login_state_hook(); %>

function initial(){
    show_banner(0);
    show_menu(4, -1, 0);
    show_footer();
    
    change_vpnc_enabled();
    load_body();
    
    update_vpnc_status(vpnc_state_last);
}

function update_vpnc_status(vpnc_state){
    this.vpnc_state_last = vpnc_state;
    var statusElem = document.getElementById('subscription_status');
    
    if (vpnc_state == '1' && document.form.vpnc_enable[0].checked) {
        statusElem.innerHTML = '<span class="label label-success">Connected</span>';
    } else {
        statusElem.innerHTML = '<span class="label label-warning">Disconnected</span>';
    }
}

function applyRule(){
    showLoading();
    
    document.form.action_mode.value = " Apply ";
    document.form.current_page.value = "/vpncli.asp";
    document.form.next_page.value = "";
    document.form.action_script.value = "restart_vpncli";
    
    document.form.submit();
}

function change_vpnc_enabled() {
    var v = document.form.vpnc_enable[0].checked;
    
    showhide_div('subscription_url_container', v);
    update_vpnc_status(vpnc_state_last);
}

</script>

<style>
    .subscription-container {
        margin-top: 15px;
    }
    #subscription_url {
        width: 400px;
    }
    #subscription_status {
        margin-left: 10px;
    }
</style>

</head>

<body onload="initial();" onunload="unload_body();">
<script>
    if(get_ap_mode()){
        alert("<#page_not_support_mode_hint#>");
        location.href = "/as.asp";
    }
</script>

<div class="wrapper">
    <div class="container-fluid" style="padding-right: 0px">
        <div class="row-fluid">
            <div class="span3"><center><div id="logo"></div></center></div>
            <div class="span9" >
                <div id="TopBanner"></div>
            </div>
        </div>
    </div>

    <br>

    <div id="Loading" class="popup_bg"></div>

    <iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0" style="position: absolute;"></iframe>

    <form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
    <input type="hidden" name="current_page" value="vpncli.asp">
    <input type="hidden" name="next_page" value="">
    <input type="hidden" name="next_host" value="">
    <input type="hidden" name="sid_list" value="LANHostConfig;">
    <input type="hidden" name="group_id" value="">
    <input type="hidden" name="action_mode" value="">
    <input type="hidden" name="action_script" value="">
    <input type="hidden" name="action_wait" value="5">
    <input type="hidden" name="flag" value="">

    <div class="container-fluid">
        <div class="row-fluid">
             <div class="span3">
                <!--Sidebar content-->
                  <!--=====Beginning of Main Menu=====-->
                  <div class="well sidebar-nav side_nav" style="padding: 0px;">
                      <ul id="mainMenu" class="clearfix"></ul>
                      <ul class="clearfix">
                          <li>
                              <div id="subMenu" class="accordion"></div>
                          </li>
                      </ul>
                  </div>
             </div>

             <div class="span9">
                <div class="box well grad_colour_dark_blue">
                    <div id="tabMenu"></div>
                    <h2 class="box_head round_top">VPN Subscription</h2>

                    <div class="round_bottom">
                        <div class="alert alert-info" style="margin: 10px;">Configure your VPN subscription settings here.</div>
                        
                        <table class="table">
                            <tr>
                                <th width="50%" style="padding-bottom: 0px; border-top: 0 none;">Enable VPN Client</th>
                                <td style="padding-bottom: 0px; border-top: 0 none;">
                                    <div class="main_itoggle">
                                        <div id="vpnc_enable_on_of">
                                            <input type="checkbox" id="vpnc_enable_fake" <% nvram_match_x("", "vpnc_enable", "1", "value=1 checked"); %><% nvram_match_x("", "vpnc_enable", "0", "value=0"); %>>
                                        </div>
                                    </div>
                                    <div style="position: absolute; margin-left: -10000px;">
                                        <input type="radio" name="vpnc_enable" id="vpnc_enable_1" class="input" value="1" onclick="change_vpnc_enabled();" <% nvram_match_x("", "vpnc_enable", "1", "checked"); %>><#checkbox_Yes#>
                                        <input type="radio" name="vpnc_enable" id="vpnc_enable_0" class="input" value="0" onclick="change_vpnc_enabled();" <% nvram_match_x("", "vpnc_enable", "0", "checked"); %>><#checkbox_No#>
                                    </div>
                                </td>
                            </tr>
                        </table>
                        
                        <div id="subscription_url_container" class="subscription-container" style="display:none">
                            <table class="table">
                                <tr>
                                    <th width="50%">Subscription URL</th>
                                    <td>
                                        <input type="text" name="vpnc_peer" id="subscription_url" class="input" maxlength="256" size="32" value="<% nvram_get_x("", "vpnc_peer"); %>" onKeyPress="return is_string(this,event);" placeholder="https://panel.example.com/api/keys/download/key_name"/>
                                        <span id="subscription_status"></span>
                                    </td>
                                </tr>
                            </table>
                            
                            <table class="table">
                                <tr>
                                    <td style="border: 0 none; padding: 0px;"><center><input name="button" type="button" class="btn btn-primary" style="width: 219px" onclick="applyRule();" value="<#CTL_apply#>"/></center></td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>
             </div>
        </div>
    </div>
    </form>

    <div id="footer"></div>
</div>

</body>
</html>