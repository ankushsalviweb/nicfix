<#
.SYNOPSIS
    NicFix - Windows Wi-Fi Troubleshooting Tool
    One click. Connection fixed. Zero dependencies.

.DESCRIPTION
    A streamlined, admin-elevated PowerShell application with WPF GUI
    that consolidates Wi-Fi troubleshooting commands into a single interface.

.NOTES
    Author: NicFix
    Version: 1.1.0
    Requires: Windows 10/11, PowerShell 5.1+
#>

#Requires -Version 5.1

# ============================================================================
# SELF-ELEVATION: Request admin rights if not already elevated
# ============================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $arguments = "& '" + $MyInvocation.MyCommand.Definition + "'"
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command $arguments"
    exit
}

# ============================================================================
# HIDE CONSOLE WINDOW: Clean GUI-only experience
# ============================================================================
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null  # 0 = SW_HIDE

# ============================================================================
# LOAD WPF ASSEMBLIES
# ============================================================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ============================================================================
# XAML UI DEFINITION - Sleek Modern Design with Sidebar Navigation
# ============================================================================
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="NicFix"
    Height="640"
    Width="820"
    WindowStartupLocation="CenterScreen"
    Background="#0a0a0f"
    ResizeMode="CanResizeWithGrip"
    FontFamily="Segoe UI">
    
    <Window.Resources>
        <!-- Compact Action Item Style -->
        <Style x:Key="ActionItem" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#e4e4e7"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,12"/>
            <Setter Property="Margin" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" 
                                BorderThickness="0,0,0,1" BorderBrush="#1a1a24"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#18181f"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#1f1f2a"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- Category Tab Style -->
        <Style x:Key="CategoryTab" TargetType="RadioButton">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#71717a"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="14,12"/>
            <Setter Property="Margin" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="Medium"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="RadioButton">
                        <Border x:Name="border" Background="{TemplateBinding Background}" 
                                BorderThickness="3,0,0,0" BorderBrush="Transparent"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#12121a"/>
                                <Setter Property="Foreground" Value="#a1a1aa"/>
                            </Trigger>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#12121a"/>
                                <Setter TargetName="border" Property="BorderBrush" Value="#6366f1"/>
                                <Setter Property="Foreground" Value="#f4f4f5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="200"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        
        <!-- SIDEBAR -->
        <Border Grid.Column="0" Background="#0f0f14" BorderBrush="#1a1a24" BorderThickness="0,0,1,0">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                
                <!-- Logo/Header -->
                <StackPanel Grid.Row="0" Margin="16,20,16,24">
                    <StackPanel Orientation="Horizontal">
                        <Border Background="#6366f1" CornerRadius="6" Width="32" Height="32" Margin="0,0,10,0">
                            <TextBlock Text="N" FontSize="16" FontWeight="Bold" Foreground="White" 
                                       HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <StackPanel VerticalAlignment="Center">
                            <TextBlock Text="NicFix" FontSize="16" FontWeight="SemiBold" Foreground="#f4f4f5"/>
                            <TextBlock Text="v1.2" FontSize="10" Foreground="#52525b"/>
                        </StackPanel>
                    </StackPanel>
                </StackPanel>
                
                <!-- Category Navigation -->
                <StackPanel Grid.Row="1">
                    <TextBlock Text="CATEGORIES" FontSize="10" FontWeight="SemiBold" Foreground="#3f3f46" 
                               Margin="16,0,16,8"/>
                    
                    <RadioButton x:Name="tabQuick" Style="{StaticResource CategoryTab}" 
                                 Content="Quick Fixes" GroupName="categories" IsChecked="True"/>
                    <RadioButton x:Name="tabNetwork" Style="{StaticResource CategoryTab}" 
                                 Content="Network Stack" GroupName="categories"/>
                    <RadioButton x:Name="tabPower" Style="{StaticResource CategoryTab}" 
                                 Content="Power Settings" GroupName="categories"/>
                    <RadioButton x:Name="tabDriver" Style="{StaticResource CategoryTab}" 
                                 Content="Driver Ops" GroupName="categories"/>
                    <RadioButton x:Name="tabDiag" Style="{StaticResource CategoryTab}" 
                                 Content="Diagnostics" GroupName="categories"/>
                </StackPanel>
                
                <!-- Footer/Credit -->
                <StackPanel Grid.Row="2" Margin="16,16,16,16">
                    <Border Background="#12121a" CornerRadius="6" Padding="10,8">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal">
                                <Ellipse Width="6" Height="6" Fill="#22c55e" Margin="0,0,6,0"/>
                                <TextBlock Text="Admin Active" FontSize="10" Foreground="#71717a"/>
                            </StackPanel>
                        </StackPanel>
                    </Border>
                    <TextBlock Text="by Ankush Salvi" FontSize="9" Foreground="#3f3f46" Margin="0,12,0,0" HorizontalAlignment="Center"/>
                    <TextBlock Text="Coded with AI" FontSize="9" Foreground="#6366f1" FontStyle="Italic" HorizontalAlignment="Center"/>
                </StackPanel>
            </Grid>
        </Border>
        
        <!-- MAIN CONTENT -->
        <Grid Grid.Column="1">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            
            <!-- Top Bar -->
            <Border Grid.Row="0" Background="#0f0f14" Padding="20,14" BorderBrush="#1a1a24" BorderThickness="0,0,0,1">
                <Grid>
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <TextBlock Name="CategoryTitle" Text="Quick Fixes" FontSize="18" FontWeight="SemiBold" Foreground="#f4f4f5"/>
                        <Border Background="#1a1a24" CornerRadius="4" Padding="8,3" Margin="12,0,0,0" VerticalAlignment="Center">
                            <TextBlock Name="CategoryBadge" Text="Safe" FontSize="10" Foreground="#22c55e"/>
                        </Border>
                    </StackPanel>
                    <Border Name="StatusBorder" Background="#1a1a24" CornerRadius="4" Padding="10,5" HorizontalAlignment="Right">
                        <TextBlock Name="StatusText" Text="Ready" FontSize="11" Foreground="#71717a"/>
                    </Border>
                </Grid>
            </Border>
            
            <!-- HERO SECTION - Most Used Actions -->
            <Border Grid.Row="1" Background="#0a0a0f" Padding="16,12" BorderBrush="#1a1a24" BorderThickness="0,0,0,1">
                <StackPanel>
                    <TextBlock Text="POPULAR FIXES" FontSize="10" FontWeight="SemiBold" Foreground="#3f3f46" Margin="4,0,0,8"/>
                    <UniformGrid Columns="4" Rows="1">
                        <!-- Hero Card 1: Flush DNS -->
                        <Button Name="heroFlushDNS" Cursor="Hand" Background="Transparent" BorderThickness="0" Margin="4">
                            <Border Background="#12121a" CornerRadius="8" Padding="12,16" BorderBrush="#1f1f2a" BorderThickness="1">
                                <StackPanel HorizontalAlignment="Center">
                                    <Border Background="#22c55e" CornerRadius="8" Width="36" Height="36" Margin="0,0,0,8">
                                        <TextBlock Text="D" FontSize="16" FontWeight="Bold" Foreground="White" 
                                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                    <TextBlock Text="Flush DNS" FontSize="11" FontWeight="Medium" Foreground="#e4e4e7" HorizontalAlignment="Center"/>
                                </StackPanel>
                            </Border>
                        </Button>
                        
                        <!-- Hero Card 2: Restart Adapter -->
                        <Button Name="heroRestartAdapter" Cursor="Hand" Background="Transparent" BorderThickness="0" Margin="4">
                            <Border Background="#12121a" CornerRadius="8" Padding="12,16" BorderBrush="#1f1f2a" BorderThickness="1">
                                <StackPanel HorizontalAlignment="Center">
                                    <Border Background="#3b82f6" CornerRadius="8" Width="36" Height="36" Margin="0,0,0,8">
                                        <TextBlock Text="R" FontSize="16" FontWeight="Bold" Foreground="White" 
                                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                    <TextBlock Text="Restart WiFi" FontSize="11" FontWeight="Medium" Foreground="#e4e4e7" HorizontalAlignment="Center"/>
                                </StackPanel>
                            </Border>
                        </Button>
                        
                        <!-- Hero Card 3: Test Connection -->
                        <Button Name="heroTestConnection" Cursor="Hand" Background="Transparent" BorderThickness="0" Margin="4">
                            <Border Background="#12121a" CornerRadius="8" Padding="12,16" BorderBrush="#1f1f2a" BorderThickness="1">
                                <StackPanel HorizontalAlignment="Center">
                                    <Border Background="#6366f1" CornerRadius="8" Width="36" Height="36" Margin="0,0,0,8">
                                        <TextBlock Text="T" FontSize="16" FontWeight="Bold" Foreground="White" 
                                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                    <TextBlock Text="Test Net" FontSize="11" FontWeight="Medium" Foreground="#e4e4e7" HorizontalAlignment="Center"/>
                                </StackPanel>
                            </Border>
                        </Button>
                        
                        <!-- Hero Card 4: Power Fix -->
                        <Button Name="heroPowerFix" Cursor="Hand" Background="Transparent" BorderThickness="0" Margin="4">
                            <Border Background="#12121a" CornerRadius="8" Padding="12,16" BorderBrush="#1f1f2a" BorderThickness="1">
                                <StackPanel HorizontalAlignment="Center">
                                    <Border Background="#f97316" CornerRadius="8" Width="36" Height="36" Margin="0,0,0,8">
                                        <TextBlock Text="P" FontSize="16" FontWeight="Bold" Foreground="White" 
                                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                    <TextBlock Text="Power Fix" FontSize="11" FontWeight="Medium" Foreground="#e4e4e7" HorizontalAlignment="Center"/>
                                </StackPanel>
                            </Border>
                        </Button>
                    </UniformGrid>
                </StackPanel>
            </Border>
            
            <!-- Feedback Banner -->
            <Border Grid.Row="2" Name="FeedbackBanner" Visibility="Collapsed" Padding="20,14" BorderBrush="#1a1a24" BorderThickness="0,0,0,1">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    
                    <Border Grid.Column="0" Name="FeedbackIconBorder" Background="#22c55e" CornerRadius="14" Width="28" Height="28" Margin="0,0,12,0">
                        <TextBlock Name="FeedbackIcon" Text="OK" FontSize="10" FontWeight="Bold" Foreground="White" 
                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    
                    <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Name="FeedbackTitle" Text="Success!" FontSize="13" FontWeight="SemiBold" Foreground="#f4f4f5"/>
                        <TextBlock Name="FeedbackMessage" Text="Fix applied." FontSize="11" Foreground="#71717a" TextWrapping="Wrap"/>
                    </StackPanel>
                    
                    <Button Grid.Column="2" Name="btnDismissFeedback" Content="x" 
                            Background="Transparent" Foreground="#52525b" BorderThickness="0" 
                            FontSize="14" Cursor="Hand" Padding="8,4"/>
                </Grid>
            </Border>
            
            <!-- Action Lists (Panels for each category) -->
            <Grid Grid.Row="3">
                <!-- Quick Fixes Panel -->
                <StackPanel Name="panelQuick" Visibility="Visible">
                    <Button Name="btnFlushDNS" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Flush DNS Cache" FontWeight="Medium"/>
                            <TextBlock Text="Clear cached website addresses" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                    <Button Name="btnReleaseIP" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Release IP Address" FontWeight="Medium"/>
                            <TextBlock Text="Disconnect from current network address" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                    <Button Name="btnRenewIP" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Renew IP Address" FontWeight="Medium"/>
                            <TextBlock Text="Request a fresh network address" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                    <Button Name="btnRestartAdapter" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Restart Wi-Fi Adapter" FontWeight="Medium"/>
                            <TextBlock Text="Turn adapter off and on again" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                </StackPanel>
                
                <!-- Network Stack Panel -->
                <StackPanel Name="panelNetwork" Visibility="Collapsed">
                    <Button Name="btnResetWinsock" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Reset Winsock Catalog" FontWeight="Medium"/>
                            <TextBlock Text="Repair Windows network communication (requires restart)" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                    <Button Name="btnResetTCPIP" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Reset TCP/IP Stack" FontWeight="Medium"/>
                            <TextBlock Text="Restore internet protocol to defaults (requires restart)" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                    <Button Name="btnClearARP" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Clear ARP Cache" FontWeight="Medium"/>
                            <TextBlock Text="Remove stale device address mappings" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                    <Button Name="btnResetFirewall" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Reset Windows Firewall" FontWeight="Medium"/>
                            <TextBlock Text="Restore firewall rules to defaults" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                </StackPanel>
                
                <!-- Power Settings Panel -->
                <StackPanel Name="panelPower" Visibility="Collapsed">
                    <Button Name="btnDisableSleep" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Disable Adapter Power Saving" FontWeight="Medium"/>
                            <TextBlock Text="Prevent Wi-Fi from turning off to save battery" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                    <Button Name="btnHighPerformance" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Set High Performance Mode" FontWeight="Medium"/>
                            <TextBlock Text="Maximum Wi-Fi power for best connection" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                </StackPanel>
                
                <!-- Driver Ops Panel -->
                <StackPanel Name="panelDriver" Visibility="Collapsed">
                    <Button Name="btnReinstallDriver" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Reinstall Network Driver" FontWeight="Medium"/>
                            <TextBlock Text="Refresh Wi-Fi driver (brief disconnect)" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                    <Button Name="btnResetDriverSettings" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Reset Driver to Defaults" FontWeight="Medium"/>
                            <TextBlock Text="Clear all custom driver settings" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                </StackPanel>
                
                <!-- Diagnostics Panel -->
                <StackPanel Name="panelDiag" Visibility="Collapsed">
                    <Button Name="btnNetworkReport" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Generate Network Report" FontWeight="Medium"/>
                            <TextBlock Text="Create detailed diagnostics report" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                    <Button Name="btnShowConfig" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Show IP Configuration" FontWeight="Medium"/>
                            <TextBlock Text="Display current network settings" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                    <Button Name="btnTestConnection" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Test Internet Connection" FontWeight="Medium"/>
                            <TextBlock Text="Check gateway, DNS, and internet access" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                    <Button Name="btnAdapterInfo" Style="{StaticResource ActionItem}">
                        <StackPanel>
                            <TextBlock Text="Show Adapter Details" FontWeight="Medium"/>
                            <TextBlock Text="View Wi-Fi adapter information" FontSize="11" Foreground="#52525b" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Button>
                </StackPanel>
            </Grid>
            
            <!-- Technical Log (Collapsible) -->
            <Expander Grid.Row="4" Header="Technical Log" IsExpanded="False" Foreground="#52525b" 
                      Background="#0a0a0f" BorderThickness="0">
                <Border Background="#0f0f14" MaxHeight="120">
                    <Grid>
                        <ScrollViewer Name="LogScrollViewer" VerticalScrollBarVisibility="Auto">
                            <TextBlock Name="LogOutput" 
                                       Padding="16,8" 
                                       Foreground="#52525b" 
                                       FontFamily="Cascadia Code, Consolas, Courier New"
                                       FontSize="10"
                                       TextWrapping="Wrap"
                                       Text="NicFix v1.2 ready."/>
                        </ScrollViewer>
                        <Button Name="btnClearLog" Content="Clear" HorizontalAlignment="Right" VerticalAlignment="Top"
                                Background="Transparent" Foreground="#3f3f46" BorderThickness="0" 
                                Cursor="Hand" Padding="8,4" Margin="0,4,8,0" FontSize="10"/>
                    </Grid>
                </Border>
            </Expander>
        </Grid>
    </Grid>
</Window>
"@

# ============================================================================
# CREATE WPF WINDOW
# ============================================================================
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get UI Elements
$logOutput = $window.FindName("LogOutput")
$logScrollViewer = $window.FindName("LogScrollViewer")
$statusText = $window.FindName("StatusText")
$statusBorder = $window.FindName("StatusBorder")

# Feedback Banner Elements
$feedbackBanner = $window.FindName("FeedbackBanner")
$feedbackIconBorder = $window.FindName("FeedbackIconBorder")
$feedbackIcon = $window.FindName("FeedbackIcon")
$feedbackTitle = $window.FindName("FeedbackTitle")
$feedbackMessage = $window.FindName("FeedbackMessage")

# Sidebar Tabs
$tabQuick = $window.FindName("tabQuick")
$tabNetwork = $window.FindName("tabNetwork")
$tabPower = $window.FindName("tabPower")
$tabDriver = $window.FindName("tabDriver")
$tabDiag = $window.FindName("tabDiag")

# Content Panels
$panelQuick = $window.FindName("panelQuick")
$panelNetwork = $window.FindName("panelNetwork")
$panelPower = $window.FindName("panelPower")
$panelDriver = $window.FindName("panelDriver")
$panelDiag = $window.FindName("panelDiag")

# Header Elements
$categoryTitle = $window.FindName("CategoryTitle")
$categoryBadge = $window.FindName("CategoryBadge")

# ============================================================================
# TAB SWITCHING LOGIC
# ============================================================================
function Switch-Panel {
    param([string]$PanelName, [string]$Title, [string]$Badge, [string]$BadgeColor)
    
    # Hide all panels
    $panelQuick.Visibility = [System.Windows.Visibility]::Collapsed
    $panelNetwork.Visibility = [System.Windows.Visibility]::Collapsed
    $panelPower.Visibility = [System.Windows.Visibility]::Collapsed
    $panelDriver.Visibility = [System.Windows.Visibility]::Collapsed
    $panelDiag.Visibility = [System.Windows.Visibility]::Collapsed
    
    # Show selected panel
    switch ($PanelName) {
        "Quick" { $panelQuick.Visibility = [System.Windows.Visibility]::Visible }
        "Network" { $panelNetwork.Visibility = [System.Windows.Visibility]::Visible }
        "Power" { $panelPower.Visibility = [System.Windows.Visibility]::Visible }
        "Driver" { $panelDriver.Visibility = [System.Windows.Visibility]::Visible }
        "Diag" { $panelDiag.Visibility = [System.Windows.Visibility]::Visible }
    }
    
    # Update header
    $categoryTitle.Text = $Title
    $categoryBadge.Text = $Badge
    $categoryBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom($BadgeColor)
}

$tabQuick.Add_Checked({ Switch-Panel -PanelName "Quick" -Title "Quick Fixes" -Badge "Safe" -BadgeColor "#22c55e" })
$tabNetwork.Add_Checked({ Switch-Panel -PanelName "Network" -Title "Network Stack" -Badge "Moderate" -BadgeColor "#eab308" })
$tabPower.Add_Checked({ Switch-Panel -PanelName "Power" -Title "Power Settings" -Badge "Common Fix" -BadgeColor "#f97316" })
$tabDriver.Add_Checked({ Switch-Panel -PanelName "Driver" -Title "Driver Operations" -Badge "Advanced" -BadgeColor "#ef4444" })
$tabDiag.Add_Checked({ Switch-Panel -PanelName "Diag" -Title "Diagnostics" -Badge "Info Only" -BadgeColor "#6366f1" })

# ============================================================================
# HUMAN-FRIENDLY MESSAGES for each fix
# ============================================================================
$FriendlyMessages = @{
    "Flush DNS Cache"              = @{
        Success = "Website addresses refreshed!"
        Detail  = "Old website address information has been cleared. If you were getting 'page not found' errors, try loading those pages again now."
        Error   = "Could not refresh website addresses"
    }
    "Release IP Address"           = @{
        Success = "Network address released!"
        Detail  = "Your computer has disconnected from the network temporarily. Click 'Renew IP' to reconnect with a fresh address."
        Error   = "Could not release network address"
    }
    "Renew IP Address"             = @{
        Success = "Fresh network address received!"
        Detail  = "Your computer got a new network address from your router. This can fix 'no internet' issues caused by address conflicts."
        Error   = "Could not get a new network address. Make sure you're connected to Wi-Fi."
    }
    "Restart Wi-Fi Adapter"        = @{
        Success = "Wi-Fi has been restarted!"
        Detail  = "Your Wi-Fi adapter has been turned off and on again. This often fixes connection drops and slow speeds."
        Error   = "Could not restart Wi-Fi. The adapter may be in use or disabled."
    }
    "Reset Winsock Catalog"        = @{
        Success = "Network communication reset!"
        Detail  = "Windows network communication has been repaired. Please RESTART your computer to complete this fix."
        Error   = "Could not reset network communication"
    }
    "Reset TCP/IP Stack"           = @{
        Success = "Internet protocol reset!"
        Detail  = "The core internet connection settings have been restored to defaults. Please RESTART your computer to complete this fix."
        Error   = "Could not reset internet protocol"
    }
    "Clear ARP Cache"              = @{
        Success = "Device address cache cleared!"
        Detail  = "Outdated information about other devices on your network has been cleared. This can fix issues connecting to local devices."
        Error   = "Could not clear device cache"
    }
    "Reset Windows Firewall"       = @{
        Success = "Firewall restored to defaults!"
        Detail  = "Windows Firewall settings have been reset. If apps were being blocked incorrectly, they should work now."
        Error   = "Could not reset firewall"
    }
    "Disable Adapter Power Saving" = @{
        Success = "Power saving disabled!"
        Detail  = "Your Wi-Fi will no longer turn off to save battery. This is a common fix for random disconnections, especially on laptops."
        Error   = "Could not change power settings"
    }
    "Set High Performance Mode"    = @{
        Success = "Maximum performance enabled!"
        Detail  = "Your computer is now running in High Performance mode. Wi-Fi is set to full power for the best connection."
        Error   = "Could not set performance mode"
    }
    "Reinstall Network Driver"     = @{
        Success = "Wi-Fi driver refreshed!"
        Detail  = "Your Wi-Fi adapter has been reinstalled. This can fix corrupted driver issues that cause connection problems."
        Error   = "Could not reinstall driver"
    }
    "Reset Driver Settings"        = @{
        Success = "Driver settings restored!"
        Detail  = "Wi-Fi adapter settings have been reset to manufacturer defaults. Any custom tweaks have been removed."
        Error   = "Could not reset driver settings"
    }
    "Generate Network Report"      = @{
        Success = "Report ready!"
        Detail  = "A detailed network report has been generated and opened in your browser. Share this with tech support if needed."
        Error   = "Could not generate report"
    }
    "Show IP Configuration"        = @{
        Success = "Network info retrieved!"
        Detail  = "Your current network settings are shown in the technical log below."
        Error   = "Could not get network info"
    }
    "Test Internet Connection"     = @{
        Success = "Connection test complete!"
        Detail  = "See the results in the technical log below. Green OKs mean things are working."
        Error   = "Connection test failed"
    }
    "Show Adapter Details"         = @{
        Success = "Adapter info retrieved!"
        Detail  = "Your Wi-Fi adapter details are shown in the technical log below."
        Error   = "Could not get adapter info"
    }
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
function Write-Log {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $icon = switch ($Type) {
        "SUCCESS" { "[OK]" }
        "ERROR" { "[ERR]" }
        "WARNING" { "[WARN]" }
        "INFO" { "[INFO]" }
        "RUNNING" { "[...]" }
        default { "[*]" }
    }
    
    $logOutput.Text += "`n$timestamp $icon $Message"
    $logScrollViewer.ScrollToEnd()
}

function Show-Feedback {
    param(
        [string]$Title,
        [string]$Message,
        [string]$Type = "success"
    )
    
    $feedbackTitle.Text = $Title
    $feedbackMessage.Text = $Message
    
    switch ($Type) {
        "success" {
            $feedbackIconBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#238636")
            $feedbackIcon.Text = "OK"
        }
        "error" {
            $feedbackIconBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#DA3633")
            $feedbackIcon.Text = "X"
        }
        "warning" {
            $feedbackIconBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#9E6A03")
            $feedbackIcon.Text = "!"
        }
        "info" {
            $feedbackIconBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#1F6FEB")
            $feedbackIcon.Text = "i"
        }
    }
    
    $feedbackBanner.Visibility = [System.Windows.Visibility]::Visible
}

function Set-Status {
    param(
        [string]$Status,
        [string]$Color = "#8B949E"
    )
    
    $statusText.Text = $Status
    
    switch ($Color) {
        "success" { 
            $statusBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#238636")
            $statusText.Foreground = [System.Windows.Media.Brushes]::White
        }
        "error" { 
            $statusBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#DA3633")
            $statusText.Foreground = [System.Windows.Media.Brushes]::White
        }
        "running" { 
            $statusBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#1F6FEB")
            $statusText.Foreground = [System.Windows.Media.Brushes]::White
        }
        default { 
            $statusBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#30363D")
            $statusText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#8B949E")
        }
    }
}

function Get-WiFiAdapter {
    try {
        $adapter = Get-NetAdapter | Where-Object { 
            $_.InterfaceDescription -match 'Wi-Fi|Wireless|WLAN|802\.11' -and 
            $_.Status -eq 'Up' 
        } | Select-Object -First 1
        
        if (-not $adapter) {
            $adapter = Get-NetAdapter | Where-Object { 
                $_.InterfaceDescription -match 'Wi-Fi|Wireless|WLAN|802\.11'
            } | Select-Object -First 1
        }
        
        return $adapter
    }
    catch {
        return $null
    }
}

function Invoke-Fix {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    
    Set-Status "Running..." "running"
    Write-Log "Starting: $Name" "RUNNING"
    
    # Get friendly messages for this fix
    $messages = $FriendlyMessages[$Name]
    
    try {
        $result = & $Action
        Set-Status "Done!" "success"
        Write-Log "$Name completed successfully" "SUCCESS"
        
        if ($result) {
            Write-Log $result "INFO"
        }
        
        # Show user-friendly feedback
        if ($messages) {
            Show-Feedback -Title $messages.Success -Message $messages.Detail -Type "success"
        }
        else {
            Show-Feedback -Title "Done!" -Message "The fix was applied successfully." -Type "success"
        }
        
        return $true
    }
    catch {
        Set-Status "Failed" "error"
        Write-Log "$Name failed: $($_.Exception.Message)" "ERROR"
        
        # Show user-friendly error
        if ($messages) {
            Show-Feedback -Title $messages.Error -Message $_.Exception.Message -Type "error"
        }
        else {
            Show-Feedback -Title "Something went wrong" -Message $_.Exception.Message -Type "error"
        }
        
        return $false
    }
}

# ============================================================================
# DISMISS FEEDBACK BUTTON
# ============================================================================
$window.FindName("btnDismissFeedback").Add_Click({
        $feedbackBanner.Visibility = [System.Windows.Visibility]::Collapsed
    })

# ============================================================================
# HERO SECTION QUICK ACCESS BUTTONS
# ============================================================================
$window.FindName("heroFlushDNS").Add_Click({
        Invoke-Fix -Name "Flush DNS Cache" -Action {
            $result = ipconfig /flushdns 2>&1
            return ($result | Out-String).Trim()
        }
    })

$window.FindName("heroRestartAdapter").Add_Click({
        Invoke-Fix -Name "Restart Wi-Fi Adapter" -Action {
            $adapter = Get-WiFiAdapter
            if ($adapter) {
                Disable-NetAdapter -Name $adapter.Name -Confirm:$false
                Start-Sleep -Seconds 2
                Enable-NetAdapter -Name $adapter.Name -Confirm:$false
                return "Adapter '$($adapter.Name)' restarted"
            }
            else {
                throw "No Wi-Fi adapter found"
            }
        }
    })

$window.FindName("heroTestConnection").Add_Click({
        Invoke-Fix -Name "Test Internet Connection" -Action {
            $wifi = Get-WiFiAdapter
            $results = @()
        
            if ($wifi) {
                $gateway = (Get-NetIPConfiguration -InterfaceIndex $wifi.ifIndex).IPv4DefaultGateway.NextHop
                if ($gateway) {
                    $ping = Test-Connection -ComputerName $gateway -Count 1 -Quiet
                    $results += "Gateway: " + $(if ($ping) { "OK" } else { "FAIL" })
                }
            }
        
            try {
                Resolve-DnsName -Name "google.com" -DnsOnly -ErrorAction Stop | Out-Null
                $results += "DNS: OK"
            }
            catch {
                $results += "DNS: FAIL"
            }
        
            $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet
            $results += "Internet: " + $(if ($ping) { "OK" } else { "FAIL" })
        
            return ($results -join " | ")
        }
    })

$window.FindName("heroPowerFix").Add_Click({
        Invoke-Fix -Name "Disable Adapter Power Saving" -Action {
            $adapter = Get-WiFiAdapter
            if ($adapter) {
                $adapterPower = Get-NetAdapterPowerManagement -Name $adapter.Name -ErrorAction SilentlyContinue
                if ($adapterPower) {
                    Set-NetAdapterPowerManagement -Name $adapter.Name -WakeOnMagicPacket Disabled -WakeOnPattern Disabled -ErrorAction SilentlyContinue
                }
            
                $pnpDevice = Get-PnpDevice | Where-Object { $_.FriendlyName -eq $adapter.InterfaceDescription }
                if ($pnpDevice) {
                    $instanceId = $pnpDevice.InstanceId
                    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$instanceId\Device Parameters\Power"
                    if (Test-Path $regPath) {
                        Set-ItemProperty -Path $regPath -Name "AllowIdleIrpInD3" -Value 0 -ErrorAction SilentlyContinue
                    }
                }
            
                return "Power saving disabled for '$($adapter.Name)'"
            }
            else {
                throw "No Wi-Fi adapter found"
            }
        }
    })

# ============================================================================
# FIX IMPLEMENTATIONS
# ============================================================================

# --- Quick Fixes ---
$window.FindName("btnFlushDNS").Add_Click({
        Invoke-Fix -Name "Flush DNS Cache" -Action {
            $result = ipconfig /flushdns 2>&1
            return ($result | Out-String).Trim()
        }
    })

$window.FindName("btnReleaseIP").Add_Click({
        Invoke-Fix -Name "Release IP Address" -Action {
            $result = ipconfig /release 2>&1
            return "IP address released"
        }
    })

$window.FindName("btnRenewIP").Add_Click({
        Invoke-Fix -Name "Renew IP Address" -Action {
            $result = ipconfig /renew 2>&1
            return "IP address renewed"
        }
    })

$window.FindName("btnRestartAdapter").Add_Click({
        Invoke-Fix -Name "Restart Wi-Fi Adapter" -Action {
            $adapter = Get-WiFiAdapter
            if ($adapter) {
                Disable-NetAdapter -Name $adapter.Name -Confirm:$false
                Start-Sleep -Seconds 2
                Enable-NetAdapter -Name $adapter.Name -Confirm:$false
                return "Adapter '$($adapter.Name)' restarted"
            }
            else {
                throw "No Wi-Fi adapter found"
            }
        }
    })

# --- Network Stack ---
$window.FindName("btnResetWinsock").Add_Click({
        Invoke-Fix -Name "Reset Winsock Catalog" -Action {
            $result = netsh winsock reset 2>&1
            return "Winsock catalog reset"
        }
    })

$window.FindName("btnResetTCPIP").Add_Click({
        Invoke-Fix -Name "Reset TCP/IP Stack" -Action {
            $result = netsh int ip reset 2>&1
            return "TCP/IP stack reset"
        }
    })

$window.FindName("btnClearARP").Add_Click({
        Invoke-Fix -Name "Clear ARP Cache" -Action {
            $result = netsh interface ip delete arpcache 2>&1
            return "ARP cache cleared"
        }
    })

$window.FindName("btnResetFirewall").Add_Click({
        Invoke-Fix -Name "Reset Windows Firewall" -Action {
            $result = netsh advfirewall reset 2>&1
            return "Windows Firewall reset"
        }
    })

# --- Power Management ---
$window.FindName("btnDisableSleep").Add_Click({
        Invoke-Fix -Name "Disable Adapter Power Saving" -Action {
            $adapter = Get-WiFiAdapter
            if ($adapter) {
                $adapterPower = Get-NetAdapterPowerManagement -Name $adapter.Name -ErrorAction SilentlyContinue
                if ($adapterPower) {
                    Set-NetAdapterPowerManagement -Name $adapter.Name -WakeOnMagicPacket Disabled -WakeOnPattern Disabled -ErrorAction SilentlyContinue
                }
            
                $pnpDevice = Get-PnpDevice | Where-Object { $_.FriendlyName -eq $adapter.InterfaceDescription }
                if ($pnpDevice) {
                    $instanceId = $pnpDevice.InstanceId
                    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$instanceId\Device Parameters\Power"
                    if (Test-Path $regPath) {
                        Set-ItemProperty -Path $regPath -Name "AllowIdleIrpInD3" -Value 0 -ErrorAction SilentlyContinue
                    }
                }
            
                return "Power saving disabled for '$($adapter.Name)'"
            }
            else {
                throw "No Wi-Fi adapter found"
            }
        }
    })

$window.FindName("btnHighPerformance").Add_Click({
        Invoke-Fix -Name "Set High Performance Mode" -Action {
            $highPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
            powercfg /setactive $highPerfGuid 2>&1
        
            powercfg /setacvalueindex SCHEME_CURRENT SUB_WIRELESS WLANADAPTER 2
            powercfg /setdcvalueindex SCHEME_CURRENT SUB_WIRELESS WLANADAPTER 2
            powercfg /setactive SCHEME_CURRENT
        
            return "High Performance mode activated"
        }
    })

# --- Driver Operations ---
$window.FindName("btnReinstallDriver").Add_Click({
        $result = [System.Windows.MessageBox]::Show(
            "This will COMPLETELY REMOVE your Wi-Fi driver and all its files.`n`nWindows will reinstall a fresh copy from scratch.`n`nYour Wi-Fi will disconnect for 30-60 seconds.`n`nContinue?",
            "Confirm Complete Driver Wipe",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )
    
        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
            Invoke-Fix -Name "Reinstall Network Driver" -Action {
                $adapter = Get-WiFiAdapter
                if ($adapter) {
                    $pnpDevice = Get-PnpDevice | Where-Object { $_.FriendlyName -eq $adapter.InterfaceDescription }
                    if ($pnpDevice) {
                        $instanceId = $pnpDevice.InstanceId
                        
                        Write-Log "Finding driver package for: $($adapter.InterfaceDescription)" "INFO"
                        
                        # Get the driver INF name for complete removal
                        $driverInfo = Get-PnpDeviceProperty -InstanceId $instanceId -KeyName "DEVPKEY_Device_DriverInfPath" -ErrorAction SilentlyContinue
                        $infName = $driverInfo.Data
                        
                        if ($infName) {
                            Write-Log "Driver INF: $infName - Performing complete wipe..." "INFO"
                            
                            # Delete the driver package completely (like checkbox "Attempt to remove the driver for this device")
                            $deleteResult = pnputil /delete-driver $infName /uninstall /force 2>&1
                            Write-Log "Driver package removal initiated" "INFO"
                            
                            Start-Sleep -Seconds 8
                            
                            # Scan for hardware changes to trigger fresh driver install
                            pnputil /scan-devices 2>&1 | Out-Null
                            Write-Log "Scanning for devices to reinstall driver..." "INFO"
                            
                            Start-Sleep -Seconds 15
                            
                            # Check if adapter came back
                            $newAdapter = Get-WiFiAdapter
                            if ($newAdapter) {
                                return "Driver completely reinstalled! '$($newAdapter.Name)' is back with fresh driver."
                            }
                            else {
                                return "Driver removed. Windows is reinstalling - please wait 30 seconds."
                            }
                        }
                        else {
                            # Fallback: use device removal if can't get INF
                            Write-Log "Could not find INF, using device removal..." "WARNING"
                            pnputil /remove-device $instanceId 2>&1 | Out-Null
                            Start-Sleep -Seconds 5
                            pnputil /scan-devices 2>&1 | Out-Null
                            Start-Sleep -Seconds 10
                            return "Device reinstalled (fallback method)"
                        }
                    }
                }
                throw "Could not find Wi-Fi device"
            }
        }
    })

$window.FindName("btnResetDriverSettings").Add_Click({
        Invoke-Fix -Name "Reset Driver Settings" -Action {
            $adapter = Get-WiFiAdapter
            if ($adapter) {
                Reset-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "*" -ErrorAction SilentlyContinue
                return "Driver settings reset for '$($adapter.Name)'"
            }
            else {
                throw "No Wi-Fi adapter found"
            }
        }
    })

# --- Diagnostics ---
$window.FindName("btnNetworkReport").Add_Click({
        Invoke-Fix -Name "Generate Network Report" -Action {
            netsh wlan show wlanreport 2>&1 | Out-Null
        
            $defaultPath = "C:\ProgramData\Microsoft\Windows\WlanReport\wlan-report-latest.html"
            if (Test-Path $defaultPath) {
                Start-Process $defaultPath
                return "Report opened in browser"
            }
            throw "Could not generate WLAN report"
        }
    })

$window.FindName("btnShowConfig").Add_Click({
        Invoke-Fix -Name "Show IP Configuration" -Action {
            $wifi = Get-WiFiAdapter
            if ($wifi) {
                $ipConfig = Get-NetIPConfiguration -InterfaceIndex $wifi.ifIndex
                $ipv4 = ($ipConfig.IPv4Address.IPAddress -join ", ")
                $gateway = ($ipConfig.IPv4DefaultGateway.NextHop -join ", ")
                $dns = ($ipConfig.DNSServer.ServerAddresses -join ", ")
            
                return "Adapter: $($wifi.Name) | IP: $ipv4 | Gateway: $gateway | DNS: $dns"
            }
            return "No Wi-Fi adapter connected"
        }
    })

$window.FindName("btnTestConnection").Add_Click({
        Invoke-Fix -Name "Test Internet Connection" -Action {
            $wifi = Get-WiFiAdapter
            $results = @()
        
            # Test gateway
            if ($wifi) {
                $gateway = (Get-NetIPConfiguration -InterfaceIndex $wifi.ifIndex).IPv4DefaultGateway.NextHop
                if ($gateway) {
                    $ping = Test-Connection -ComputerName $gateway -Count 1 -Quiet
                    $results += "Gateway: " + $(if ($ping) { "OK" } else { "FAIL" })
                }
            }
        
            # Test DNS
            try {
                Resolve-DnsName -Name "google.com" -DnsOnly -ErrorAction Stop | Out-Null
                $results += "DNS: OK"
            }
            catch {
                $results += "DNS: FAIL"
            }
        
            # Test Internet
            $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet
            $results += "Internet: " + $(if ($ping) { "OK" } else { "FAIL" })
        
            return ($results -join " | ")
        }
    })

$window.FindName("btnAdapterInfo").Add_Click({
        Invoke-Fix -Name "Show Adapter Details" -Action {
            $adapter = Get-WiFiAdapter
            if ($adapter) {
                return "$($adapter.Name) | $($adapter.Status) | $($adapter.LinkSpeed) | Driver: $($adapter.DriverVersion)"
            }
            return "No Wi-Fi adapter found"
        }
    })

# --- Clear Log ---
$window.FindName("btnClearLog").Add_Click({
        $logOutput.Text = "Log cleared."
        $feedbackBanner.Visibility = [System.Windows.Visibility]::Collapsed
    })

# ============================================================================
# SHOW WINDOW
# ============================================================================
$window.ShowDialog() | Out-Null
