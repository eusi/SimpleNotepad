local _, app = ...
local keys = {
    "Notes", "Note %d", "Show/hide SimpleNotepad", "Search notes", "No matching notes",
    "Close tab temporarily", "Rename note", "Permanently delete note", "All notes",
    "Previous note", "Next note", "Undo (Ctrl+Z)", "Redo (Ctrl+Y)", "Close", "Minimize",
    "Settings", "Auto-hide toolbar", "New note", "Close settings", "Rename note (Enter to save)",
    "Window opacity", "Window scale", "Minimap icon: on", "Minimap icon: off",
    "Restore SimpleNotepad", "Resize", "Permanently delete this note?",
}
local translations = {
    deDE = {
        "Notizen", "Notiz %d", "SimpleNotepad anzeigen/ausblenden", "Notizen durchsuchen", "Keine passenden Notizen",
        "Tab vorübergehend schließen", "Notiz umbenennen", "Notiz endgültig löschen", "Alle Notizen",
        "Vorherige Notiz", "Nächste Notiz", "Rückgängig (Strg+Z)", "Wiederholen (Strg+Y)", "Schließen", "Minimieren",
        "Einstellungen", "Werkzeugleiste automatisch ausblenden", "Neue Notiz", "Einstellungen schließen", "Notiz umbenennen (Enter zum Speichern)",
        "Deckkraft des Fensters", "Fensterskalierung", "Minikarten-Symbol: an", "Minikarten-Symbol: aus",
        "SimpleNotepad wiederherstellen", "Größe ändern", "Diese Notiz endgültig löschen?",
    },
    frFR = {
        "Notes", "Note %d", "Afficher/masquer SimpleNotepad", "Rechercher des notes", "Aucune note correspondante",
        "Fermer temporairement l’onglet", "Renommer la note", "Supprimer définitivement la note", "Toutes les notes",
        "Note précédente", "Note suivante", "Annuler (Ctrl+Z)", "Rétablir (Ctrl+Y)", "Fermer", "Réduire",
        "Paramètres", "Masquer automatiquement la barre d’outils", "Nouvelle note", "Fermer les paramètres", "Renommer la note (Entrée pour enregistrer)",
        "Opacité de la fenêtre", "Échelle de la fenêtre", "Icône de minicarte : activée", "Icône de minicarte : désactivée",
        "Restaurer SimpleNotepad", "Redimensionner", "Supprimer définitivement cette note ?",
    },
    esES = {
        "Notas", "Nota %d", "Mostrar/ocultar SimpleNotepad", "Buscar notas", "No se encontraron notas",
        "Cerrar pestaña temporalmente", "Renombrar nota", "Eliminar nota permanentemente", "Todas las notas",
        "Nota anterior", "Nota siguiente", "Deshacer (Ctrl+Z)", "Rehacer (Ctrl+Y)", "Cerrar", "Minimizar",
        "Ajustes", "Ocultar automáticamente la barra", "Nueva nota", "Cerrar ajustes", "Renombrar nota (Intro para guardar)",
        "Opacidad de la ventana", "Escala de la ventana", "Icono del minimapa: activado", "Icono del minimapa: desactivado",
        "Restaurar SimpleNotepad", "Cambiar tamaño", "¿Eliminar esta nota permanentemente?",
    },
    ptBR = {
        "Notas", "Nota %d", "Mostrar/ocultar SimpleNotepad", "Pesquisar notas", "Nenhuma nota encontrada",
        "Fechar aba temporariamente", "Renomear nota", "Excluir nota permanentemente", "Todas as notas",
        "Nota anterior", "Próxima nota", "Desfazer (Ctrl+Z)", "Refazer (Ctrl+Y)", "Fechar", "Minimizar",
        "Configurações", "Ocultar barra automaticamente", "Nova nota", "Fechar configurações", "Renomear nota (Enter para salvar)",
        "Opacidade da janela", "Escala da janela", "Ícone do minimapa: ativado", "Ícone do minimapa: desativado",
        "Restaurar SimpleNotepad", "Redimensionar", "Excluir esta nota permanentemente?",
    },
    itIT = {
        "Note", "Nota %d", "Mostra/nascondi SimpleNotepad", "Cerca note", "Nessuna nota trovata",
        "Chiudi temporaneamente la scheda", "Rinomina nota", "Elimina nota definitivamente", "Tutte le note",
        "Nota precedente", "Nota successiva", "Annulla (Ctrl+Z)", "Ripristina (Ctrl+Y)", "Chiudi", "Riduci a icona",
        "Impostazioni", "Nascondi automaticamente la barra", "Nuova nota", "Chiudi impostazioni", "Rinomina nota (Invio per salvare)",
        "Opacità finestra", "Scala finestra", "Icona minimappa: attiva", "Icona minimappa: disattiva",
        "Ripristina SimpleNotepad", "Ridimensiona", "Eliminare definitivamente questa nota?",
    },
    ruRU = {
        "Заметки", "Заметка %d", "Показать/скрыть SimpleNotepad", "Поиск заметок", "Заметки не найдены",
        "Временно закрыть вкладку", "Переименовать заметку", "Удалить заметку навсегда", "Все заметки",
        "Предыдущая заметка", "Следующая заметка", "Отменить (Ctrl+Z)", "Повторить (Ctrl+Y)", "Закрыть", "Свернуть",
        "Настройки", "Автоматически скрывать панель", "Новая заметка", "Закрыть настройки", "Переименовать заметку (Enter для сохранения)",
        "Непрозрачность окна", "Масштаб окна", "Значок у миникарты: вкл.", "Значок у миникарты: выкл.",
        "Восстановить SimpleNotepad", "Изменить размер", "Удалить эту заметку навсегда?",
    },
    koKR = {
        "메모", "메모 %d", "SimpleNotepad 표시/숨기기", "메모 검색", "일치하는 메모 없음",
        "탭 임시 닫기", "메모 이름 변경", "메모 영구 삭제", "모든 메모",
        "이전 메모", "다음 메모", "실행 취소 (Ctrl+Z)", "다시 실행 (Ctrl+Y)", "닫기", "최소화",
        "설정", "도구 모음 자동 숨기기", "새 메모", "설정 닫기", "메모 이름 변경 (Enter로 저장)",
        "창 불투명도", "창 배율", "미니맵 아이콘: 켜짐", "미니맵 아이콘: 꺼짐",
        "SimpleNotepad 복원", "크기 조절", "이 메모를 영구 삭제할까요?",
    },
    zhCN = {
        "笔记", "笔记 %d", "显示/隐藏 SimpleNotepad", "搜索笔记", "未找到匹配笔记",
        "暂时关闭标签", "重命名笔记", "永久删除笔记", "所有笔记",
        "上一篇笔记", "下一篇笔记", "撤销（Ctrl+Z）", "重做（Ctrl+Y）", "关闭", "最小化",
        "设置", "自动隐藏工具栏", "新建笔记", "关闭设置", "重命名笔记（回车保存）",
        "窗口不透明度", "窗口缩放", "小地图图标：开", "小地图图标：关",
        "还原 SimpleNotepad", "调整大小", "永久删除这篇笔记？",
    },
    zhTW = {
        "筆記", "筆記 %d", "顯示/隱藏 SimpleNotepad", "搜尋筆記", "找不到相符筆記",
        "暫時關閉分頁", "重新命名筆記", "永久刪除筆記", "所有筆記",
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
local extraKeys = {
    "Name for the new note", "Save", "Cancel", "Background color", "Accent color",
    "Reset appearance", "Style: WoW", "Style: modern", "Lock window", "Unlock window",
    "Minimized button: icon", "Minimized button: SNP", "Hold, then drag to reorder",
    "Drag left or right to reorder", "Click to open. Drag to move.",
}
local extraTranslations = {
    deDE = {
        "Name der neuen Notiz", "Speichern", "Abbrechen", "Hintergrundfarbe", "Akzentfarbe",
        "Darstellung zurücksetzen", "Stil: WoW", "Stil: Modern", "Fenster sperren", "Fenster entsperren",
        "Minimiertes Fenster: Icon", "Minimiertes Fenster: SNP", "Gedrückt halten, dann zum Sortieren ziehen",
        "Zum Sortieren nach links oder rechts ziehen", "Klicken zum Öffnen. Ziehen zum Verschieben.",
    },
    frFR = {
        "Nom de la nouvelle note", "Enregistrer", "Annuler", "Couleur de fond", "Couleur d’accent",
        "Réinitialiser l’apparence", "Style : WoW", "Style : moderne", "Verrouiller la fenêtre", "Déverrouiller la fenêtre",
        "Bouton réduit : icône", "Bouton réduit : SNP", "Maintenir, puis glisser pour réorganiser",
        "Glisser à gauche ou à droite pour réorganiser", "Cliquer pour ouvrir. Glisser pour déplacer.",
    },
    esES = {
        "Nombre de la nueva nota", "Guardar", "Cancelar", "Color de fondo", "Color de acento",
        "Restablecer apariencia", "Estilo: WoW", "Estilo: moderno", "Bloquear ventana", "Desbloquear ventana",
        "Botón minimizado: icono", "Botón minimizado: SNP", "Mantén pulsado y arrastra para ordenar",
        "Arrastra a izquierda o derecha para ordenar", "Haz clic para abrir. Arrastra para mover.",
    },
    ptBR = {
        "Nome da nova nota", "Salvar", "Cancelar", "Cor de fundo", "Cor de destaque",
        "Redefinir aparência", "Estilo: WoW", "Estilo: moderno", "Bloquear janela", "Desbloquear janela",
        "Botão minimizado: ícone", "Botão minimizado: SNP", "Segure e arraste para reordenar",
        "Arraste para a esquerda ou direita para reordenar", "Clique para abrir. Arraste para mover.",
    },
    itIT = {
        "Nome della nuova nota", "Salva", "Annulla", "Colore di sfondo", "Colore di risalto",
        "Ripristina aspetto", "Stile: WoW", "Stile: moderno", "Blocca finestra", "Sblocca finestra",
        "Pulsante ridotto: icona", "Pulsante ridotto: SNP", "Tieni premuto e trascina per riordinare",
        "Trascina a sinistra o a destra per riordinare", "Clicca per aprire. Trascina per spostare.",
    },
    ruRU = {
        "Название новой заметки", "Сохранить", "Отмена", "Цвет фона", "Цвет акцента",
        "Сбросить оформление", "Стиль: WoW", "Стиль: современный", "Закрепить окно", "Открепить окно",
        "Кнопка свёрнутого окна: значок", "Кнопка свёрнутого окна: SNP", "Удерживайте и перетащите для сортировки",
        "Перетащите влево или вправо для сортировки", "Нажмите, чтобы открыть. Перетащите, чтобы переместить.",
    },
    koKR = {
        "새 메모 이름", "저장", "취소", "배경색", "강조색",
        "모양 초기화", "스타일: WoW", "스타일: 모던", "창 잠금", "창 잠금 해제",
        "최소화 버튼: 아이콘", "최소화 버튼: SNP", "길게 누른 뒤 끌어서 순서 변경",
        "왼쪽이나 오른쪽으로 끌어서 순서 변경", "클릭하여 열기. 끌어서 이동.",
    },
    zhCN = {
        "新笔记名称", "保存", "取消", "背景颜色", "强调色",
        "重置外观", "风格：WoW", "风格：现代", "锁定窗口", "解锁窗口",
        "最小化按钮：图标", "最小化按钮：SNP", "长按后拖动以排序",
        "向左或向右拖动以排序", "点击打开，拖动移动。",
    },
    zhTW = {
        "新筆記名稱", "儲存", "取消", "背景顏色", "強調色",
        "重設外觀", "風格：WoW", "風格：現代", "鎖定視窗", "解鎖視窗",
        "最小化按鈕：圖示", "最小化按鈕：SNP", "長按後拖曳以排序",
        "向左或向右拖曳以排序", "點擊開啟，拖曳移動。",
    },
}
extraTranslations.esMX = extraTranslations.esES
local extra = extraTranslations[language]
for index,key in ipairs(extraKeys) do strings[key] = extra and extra[index] or key end
local sharingKeys = {
    "Character-only note. Click to share with all characters.",
    "Shared with all characters. Click to make character-only.",
    "Permanently delete this shared note for all characters?",
}
local sharingTranslations = {
    deDE = {"Nur für diesen Charakter. Klicken, um die Notiz mit allen Charakteren zu teilen.", "Mit allen Charakteren geteilt. Klicken, um die Notiz nur für diesen Charakter zu behalten.", "Diese geteilte Notiz für alle Charaktere endgültig löschen?"},
    frFR = {"Note propre à ce personnage. Cliquer pour la partager avec tous les personnages.", "Partagée avec tous les personnages. Cliquer pour la réserver à ce personnage.", "Supprimer définitivement cette note partagée pour tous les personnages ?"},
    esES = {"Nota de este personaje. Haz clic para compartirla con todos los personajes.", "Compartida con todos los personajes. Haz clic para conservarla solo en este personaje.", "¿Eliminar permanentemente esta nota compartida para todos los personajes?"},
    ptBR = {"Nota deste personagem. Clique para compartilhar com todos os personagens.", "Compartilhada com todos os personagens. Clique para manter apenas neste personagem.", "Excluir permanentemente esta nota compartilhada de todos os personagens?"},
    itIT = {"Nota di questo personaggio. Clicca per condividerla con tutti i personaggi.", "Condivisa con tutti i personaggi. Clicca per mantenerla solo per questo personaggio.", "Eliminare definitivamente questa nota condivisa per tutti i personaggi?"},
    ruRU = {"Личная заметка персонажа. Нажмите, чтобы открыть доступ всем персонажам.", "Доступна всем персонажам. Нажмите, чтобы оставить только этому персонажу.", "Навсегда удалить эту общую заметку для всех персонажей?"},
    koKR = {"이 캐릭터만의 메모입니다. 클릭하면 모든 캐릭터와 공유합니다.", "모든 캐릭터와 공유 중입니다. 클릭하면 이 캐릭터만 사용합니다.", "이 공유 메모를 모든 캐릭터에서 영구적으로 삭제할까요?"},
    zhCN = {"仅此角色可见。点击与所有角色共享此笔记。", "所有角色共享。点击将此笔记改为仅此角色可见。", "确定为所有角色永久删除此共享笔记？"},
    zhTW = {"僅此角色可見。點擊與所有角色共用此筆記。", "所有角色共用。點擊將此筆記改為僅此角色可見。", "確定為所有角色永久刪除此共用筆記？"},
}
sharingTranslations.esMX = sharingTranslations.esES
local sharing = sharingTranslations[language]
for index, key in ipairs(sharingKeys) do strings[key] = sharing and sharing[index] or key end
app.L = strings

local folded = {}
local upper = {"À","Á","Â","Ã","Ä","Å","Æ","Ç","È","É","Ê","Ë","Ì","Í","Î","Ï","Ñ","Ò","Ó","Ô","Õ","Ö","Ø","Ù","Ú","Û","Ü","Ý","Œ","Ÿ","ẞ","А","Б","В","Г","Д","Е","Ё","Ж","З","И","Й","К","Л","М","Н","О","П","Р","С","Т","У","Ф","Х","Ц","Ч","Ш","Щ","Ъ","Ы","Ь","Э","Ю","Я"}
local lower = {"à","á","â","ã","ä","å","æ","ç","è","é","ê","ë","ì","í","î","ï","ñ","ò","ó","ô","õ","ö","ø","ù","ú","û","ü","ý","œ","ÿ","ß","а","б","в","г","д","е","ё","ж","з","и","й","к","л","м","н","о","п","р","с","т","у","ф","х","ц","ч","ш","щ","ъ","ы","ь","э","ю","я"}
for index,value in ipairs(upper) do folded[value] = lower[index] end
function app.Fold(text)
    return string.lower((text:gsub("[\194-\244][\128-\191]+",folded)))
end

function app.Find(text,query,offset)
    -- Map folded matches back to UTF-8 byte offsets used by the EditBox cursor.
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
    local from=1
    if offset and offset>1 then
        from=nil
        for index,start in ipairs(starts) do if start>=offset then from=index; break end end
        if not from then return end
    end
    local first,last=string.find(table.concat(chunks),app.Fold(query),from,true)
    if first then return starts[first],ends[last] end
end
