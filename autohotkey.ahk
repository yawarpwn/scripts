;Shift + Alt + R -> Reload configuration
+!r::Reload

; Win + F -> maximize/restore window
#f::
WinGet, winState, MinMax, A
If (winState = 1) {
    WinRestore, A
} Else {
    WinMaximize, A
}
return

; Win + Enter -> open WezTerm
#Enter::
Run, "c:\Program Files\WezTerm\wezterm-gui.exe"

Return

; Win + W -> Open Brave Browser 
#w::Run "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"

; Remap CapsLock + HJKL to Arrow Keys
CapsLock & h::Send {Left}
CapsLock & j::Send {Down}
CapsLock & k::Send {Up}
CapsLock & l::Send {Right}


;  Win + 1 -> Desktop 1
#1::
   Send, ^#{Left}
   return
; Win + 2 -> Desktop 2
#2::
   ; Enviar las teclas para cambiar al segundo escritorio
   Send, ^#{Right}
   return
