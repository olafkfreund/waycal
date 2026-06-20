import Quickshell
import Quickshell.Io

// waycal entrypoint. Three independent widgets, each an always-on layer-shell
// window plus a toggleable overlay, each driven by its own IPC target so niri
// keybinds can control them separately:
//   qs -c waycal ipc call calendar toggle
//   qs -c waycal ipc call mail toggle
//   qs -c waycal ipc call tasks toggle
ShellRoot {
    // ---------------- Calendar ----------------
    AgendaWidget {}
    MonthDashboard {}
    IpcHandler {
        target: "calendar"
        function toggle(): void { CalendarService.dashboardOpen = !CalendarService.dashboardOpen }
        function show(): void { CalendarService.dashboardOpen = true }
        function hide(): void { CalendarService.dashboardOpen = false }
        function widget(): void { CalendarService.widgetVisible = !CalendarService.widgetVisible }
        function refresh(): void { CalendarService.refresh() }
    }

    // ---------------- Mail ----------------
    MailWidget {}
    MailOverlay {}
    IpcHandler {
        target: "mail"
        function toggle(): void { MailService.overlayOpen = !MailService.overlayOpen }
        function show(): void { MailService.overlayOpen = true }
        function hide(): void { MailService.overlayOpen = false }
        function widget(): void { MailService.widgetVisible = !MailService.widgetVisible }
        function refresh(): void { MailService.refresh() }
    }

    // ---------------- Tasks ----------------
    TasksWidget {}
    TasksOverlay {}
    IpcHandler {
        target: "tasks"
        function toggle(): void { TasksService.overlayOpen = !TasksService.overlayOpen }
        function show(): void { TasksService.overlayOpen = true }
        function hide(): void { TasksService.overlayOpen = false }
        function widget(): void { TasksService.widgetVisible = !TasksService.widgetVisible }
        function refresh(): void { TasksService.refresh() }
    }
}
