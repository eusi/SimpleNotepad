local _, app = ...
local keys = {
    "Notes", "Note %d", "Show/hide SimpleNotepad", "Search notes", "No matching notes",
    "Close tab (keep note)", "Rename note", "Permanently delete note", "All notes",
    "Previous note", "Next note", "Undo (Ctrl+Z)", "Redo (Ctrl+Y)", "Close", "Minimize",
    "Settings", "Auto-hide toolbar", "New note", "Close settings", "Rename note (Enter to save)",
    "Window opacity", "Window scale", "Minimap icon: on", "Minimap icon: off",
    "Restore SimpleNotepad", "Resize", "Permanently delete this note?",
}
local translations = {
    deDE = {
        "Notizen", "Notiz %d", "SimpleNotepad anzeigen/ausblenden", "Notizen durchsuchen", "Keine passenden Notizen",
        "Tab schließen (Notiz behalten)", "Notiz umbenennen", "Notiz endgültig löschen", "Alle Notizen",
        "Vorherige Notiz", "Nächste Notiz", "Rückgängig (Strg+Z)", "Wiederholen (Strg+Y)", "Schließen", "Minimieren",
        "Einstellungen", "Werkzeugleiste automatisch ausblenden", "Neue Notiz", "Einstellungen schließen", "Notiz umbenennen (Enter zum Speichern)",
        "Deckkraft des Fensters", "Fensterskalierung", "Minikarten-Symbol: an", "Minikarten-Symbol: aus",
        "SimpleNotepad wiederherstellen", "Größe ändern", "Diese Notiz endgültig löschen?",
    },
    frFR = {
        "Notes", "Note %d", "Afficher/masquer SimpleNotepad", "Rechercher des notes", "Aucune note correspondante",
        "Fermer l’onglet (conserver la note)", "Renommer la note", "Supprimer définitivement la note", "Toutes les notes",
        "Note précédente", "Note suivante", "Annuler (Ctrl+Z)", "Rétablir (Ctrl+Y)", "Fermer", "Réduire",
        "Paramètres", "Masquer automatiquement la barre d’outils", "Nouvelle note", "Fermer les paramètres", "Renommer la note (Entrée pour enregistrer)",
        "Opacité de la fenêtre", "Échelle de la fenêtre", "Icône de minicarte : activée", "Icône de minicarte : désactivée",
        "Restaurer SimpleNotepad", "Redimensionner", "Supprimer définitivement cette note ?",
    },
    esES = {
        "Notas", "Nota %d", "Mostrar/ocultar SimpleNotepad", "Buscar notas", "No se encontraron notas",
        "Cerrar pestaña (conservar nota)", "Renombrar nota", "Eliminar nota permanentemente", "Todas las notas",
        "Nota anterior", "Nota siguiente", "Deshacer (Ctrl+Z)", "Rehacer (Ctrl+Y)", "Cerrar", "Minimizar",
        "Ajustes", "Ocultar automáticamente la barra", "Nueva nota", "Cerrar ajustes", "Renombrar nota (Intro para guardar)",
        "Opacidad de la ventana", "Escala de la ventana", "Icono del minimapa: activado", "Icono del minimapa: desactivado",
        "Restaurar SimpleNotepad", "Cambiar tamaño", "¿Eliminar esta nota permanentemente?",
    },
    ptBR = {
        "Notas", "Nota %d", "Mostrar/ocultar SimpleNotepad", "Pesquisar notas", "Nenhuma nota encontrada",
        "Fechar aba (manter nota)", "Renomear nota", "Excluir nota permanentemente", "Todas as notas",
        "Nota anterior", "Próxima nota", "Desfazer (Ctrl+Z)", "Refazer (Ctrl+Y)", "Fechar", "Minimizar",
        "Configurações", "Ocultar barra automaticamente", "Nova nota", "Fechar configurações", "Renomear nota (Enter para salvar)",
        "Opacidade da janela", "Escala da janela", "Ícone do minimapa: ativado", "Ícone do minimapa: desativado",
        "Restaurar SimpleNotepad", "Redimensionar", "Excluir esta nota permanentemente?",
    },
    itIT = {
        "Note", "Nota %d", "Mostra/nascondi SimpleNotepad", "Cerca note", "Nessuna nota trovata",
        "Chiudi scheda (conserva nota)", "Rinomina nota", "Elimina nota definitivamente", "Tutte le note",
        "Nota precedente", "Nota successiva", "Annulla (Ctrl+Z)", "Ripristina (Ctrl+Y)", "Chiudi", "Riduci a icona",
        "Impostazioni", "Nascondi automaticamente la barra", "Nuova nota", "Chiudi impostazioni", "Rinomina nota (Invio per salvare)",
        "Opacità finestra", "Scala finestra", "Icona minimappa: attiva", "Icona minimappa: disattiva",
        "Ripristina SimpleNotepad", "Ridimensiona", "Eliminare definitivamente questa nota?",
    },
    ruRU = {
        "Заметки", "Заметка %d", "Показать/скрыть SimpleNotepad", "Поиск заметок", "Заметки не найдены",
        "Закрыть вкладку (сохранить заметку)", "Переименовать заметку", "Удалить заметку навсегда", "Все заметки",
        "Предыдущая заметка", "Следующая заметка", "Отменить (Ctrl+Z)", "Повторить (Ctrl+Y)", "Закрыть", "Свернуть",
        "Настройки", "Автоматически скрывать панель", "Новая заметка", "Закрыть настройки", "Переименовать заметку (Enter для сохранения)",
        "Непрозрачность окна", "Масштаб окна", "Значок у миникарты: вкл.", "Значок у миникарты: выкл.",
        "Восстановить SimpleNotepad", "Изменить размер", "Удалить эту заметку навсегда?",
    },
    koKR = {
        "메모", "메모 %d", "SimpleNotepad 표시/숨기기", "메모 검색", "일치하는 메모 없음",
        "탭 닫기 (메모 유지)", "메모 이름 변경", "메모 영구 삭제", "모든 메모",
        "이전 메모", "다음 메모", "실행 취소 (Ctrl+Z)", "다시 실행 (Ctrl+Y)", "닫기", "최소화",
        "설정", "도구 모음 자동 숨기기", "새 메모", "설정 닫기", "메모 이름 변경 (Enter로 저장)",
        "창 불투명도", "창 배율", "미니맵 아이콘: 켜짐", "미니맵 아이콘: 꺼짐",
        "SimpleNotepad 복원", "크기 조절", "이 메모를 영구 삭제할까요?",
    },
    zhCN = {
        "笔记", "笔记 %d", "显示/隐藏 SimpleNotepad", "搜索笔记", "未找到匹配笔记",
        "关闭标签（保留笔记）", "重命名笔记", "永久删除笔记", "所有笔记",
        "上一篇笔记", "下一篇笔记", "撤销（Ctrl+Z）", "重做（Ctrl+Y）", "关闭", "最小化",
        "设置", "自动隐藏工具栏", "新建笔记", "关闭设置", "重命名笔记（回车保存）",
        "窗口不透明度", "窗口缩放", "小地图图标：开", "小地图图标：关",
        "还原 SimpleNotepad", "调整大小", "永久删除这篇笔记？",
    },
    zhTW = {
        "筆記", "筆記 %d", "顯示/隱藏 SimpleNotepad", "搜尋筆記", "找不到相符筆記",
        "關閉分頁（保留筆記）", "重新命名筆記", "永久刪除筆記", "所有筆記",
        "上一篇筆記", "下一篇筆記", "復原（Ctrl+Z）", "重做（Ctrl+Y）", "關閉", "最小化",
        "設定", "自動隱藏工具列", "新增筆記", "關閉設定", "重新命名筆記（Enter 儲存）",
        "視窗不透明度", "視窗縮放", "小地圖圖示：開", "小地圖圖示：關",
        "還原 SimpleNotepad", "調整大小", "永久刪除這篇筆記？",
    },
}
translations.esMX = translations.esES
local language = GetLocale and GetLocale() or "enUS"
local selected = translations[language]
local strings = setmetatable({}, {__index = function(_,key) return key end})
for index,key in ipairs(keys) do strings[key] = selected and selected[index] or key end
app.L = strings

local folded = {}
local upper = {"À","Á","Â","Ã","Ä","Å","Æ","Ç","È","É","Ê","Ë","Ì","Í","Î","Ï","Ñ","Ò","Ó","Ô","Õ","Ö","Ø","Ù","Ú","Û","Ü","Ý","Œ","Ÿ","ẞ","А","Б","В","Г","Д","Е","Ё","Ж","З","И","Й","К","Л","М","Н","О","П","Р","С","Т","У","Ф","Х","Ц","Ч","Ш","Щ","Ъ","Ы","Ь","Э","Ю","Я"}
local lower = {"à","á","â","ã","ä","å","æ","ç","è","é","ê","ë","ì","í","î","ï","ñ","ò","ó","ô","õ","ö","ø","ù","ú","û","ü","ý","œ","ÿ","ß","а","б","в","г","д","е","ё","ж","з","и","й","к","л","м","н","о","п","р","с","т","у","ф","х","ц","ч","ш","щ","ъ","ы","ь","э","ю","я"}
for index,value in ipairs(upper) do folded[value] = lower[index] end
function app.Fold(text)
    return string.lower((text:gsub("[\194-\244][\128-\191]+",folded)))
end

function app.Find(text,query)
    local chunks,starts,ends = {},{},{}
    local cursor,normalized = 1,0
    for character in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        local value=app.Fold(character)
        chunks[#chunks+1]=value
        for index=1,#value do
            starts[normalized+index]=cursor
            ends[normalized+index]=cursor+#character-1
        end
        cursor=cursor+#character; normalized=normalized+#value
    end
    local first,last=string.find(table.concat(chunks),app.Fold(query),1,true)
    if first then return starts[first],ends[last] end
end
