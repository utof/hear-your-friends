-- Follows Unreal's active language; never changes game or OS language settings.
local messages={
 en={
  voice_title='Voice chat volume',master='Master voice volume',
  players_title='Individual player volume',no_players='No other players connected.',
  report='Report a mod bug',support='Support on Ko-fi',range_hint="0 = silent · 1 = normal · Master × player, up to 16×",
  load_world='Load a world to adjust player volume.',waiting_voice='Waiting for voice chat.',
  voice_error='Voice update failed. Use Report a mod bug.',controls_error='Controls unavailable. Use Report a mod bug.',
  report_saved='Diagnostics saved. Add reproduction steps in GitHub.',report_failed='Could not save diagnostics. The issue contains a summary.',
  ready='Adjust voices in Escape → Manage Players, or F8.',
  native_master="All voices",native_voice="Voice",
  native_report='REPORT MOD BUG',native_support='SUPPORT · KO-FI',
  reset="Reset",
  effective="Effective %.2f×: master %.2f× × player %.2f×",
 },
 fr={
  voice_title='Volume du chat vocal',master='Volume vocal général',
  players_title='Volume de chaque joueur',no_players="Aucun autre joueur connecté.",
  report='Signaler un bug du mod',support='Soutenir sur Ko-fi',range_hint="0 = muet · 1 = normal · Général × joueur, jusqu’à 16×",
  load_world='Chargez une partie pour régler les voix.',waiting_voice='En attente du chat vocal.',
  voice_error='Échec du réglage vocal. Signalez un bug du mod.',controls_error='Commandes indisponibles. Signalez un bug du mod.',
  report_saved='Diagnostic enregistré. Ajoutez les étapes sur GitHub.',report_failed="Impossible d’enregistrer le diagnostic. Un résumé figure dans le ticket.",
  ready='Réglez les voix dans Échap → Gestion des joueurs, ou F8.',
  native_master="Toutes les voix",native_voice="Voix",
  native_report='SIGNALER UN BUG',native_support='SOUTENIR · KO-FI',
  reset="Réinitialiser",
  effective="Volume effectif %.2f× : général %.2f× × joueur %.2f×",
 },
 de={
  voice_title='Sprachchat-Lautstärke',master='Gesamte Sprachlautstärke',
  players_title='Lautstärke je Spieler',no_players='Keine weiteren Spieler verbunden.',
  report='Mod-Fehler melden',support='Auf Ko-fi unterstützen',range_hint="0 = stumm · 1 = normal · Gesamt × Spieler, bis 16×",
  load_world='Lade eine Welt, um Stimmen einzustellen.',waiting_voice='Warte auf Sprachchat.',
  voice_error='Sprachanpassung fehlgeschlagen. Bitte Mod-Fehler melden.',controls_error='Steuerung nicht verfügbar. Bitte Mod-Fehler melden.',
  report_saved='Diagnose gespeichert. Ergänze die Schritte auf GitHub.',report_failed='Diagnose konnte nicht gespeichert werden. Der Bericht enthält eine Zusammenfassung.',
  ready='Stimmen unter Esc → Spielerverwaltung oder mit F8 einstellen.',
  native_master="Alle Stimmen",native_voice="Stimme",
  native_report='MOD-FEHLER MELDEN',native_support='UNTERSTÜTZEN · KO-FI',
  reset="Zurücksetzen",
  effective="Effektiv %.2f×: gesamt %.2f× × Spieler %.2f×",
 },
 pt={
  voice_title='Volume do chat de voz',master='Volume geral das vozes',
  players_title='Volume individual dos jogadores',no_players='Nenhum outro jogador conectado.',
  report='Relatar erro do mod',support='Apoiar no Ko-fi',range_hint="0 = mudo · 1 = normal · Geral × jogador, até 16×",
  load_world='Entre em um mundo para ajustar as vozes.',waiting_voice='Aguardando o chat de voz.',
  voice_error='Falha ao ajustar as vozes. Relate um erro do mod.',controls_error='Controles indisponíveis. Relate um erro do mod.',
  report_saved='Diagnóstico salvo. Adicione os passos no GitHub.',report_failed='Não foi possível salvar o diagnóstico. O relato inclui um resumo.',
  ready='Ajuste as vozes em Esc → Gerenciar jogadores, ou F8.',
  native_master="Todas as vozes",native_voice="Voz",
  native_report='RELATAR ERRO DO MOD',native_support='APOIAR · KO-FI',
  reset="Redefinir",
  effective="Volume efetivo %.2f×: geral %.2f× × jogador %.2f×",
 },
 ru={
  voice_title='Громкость голосового чата',master='Общая громкость голосов',
  players_title='Громкость отдельных игроков',no_players='Других игроков нет.',
  report='Сообщить об ошибке мода',support='Поддержать на Ko-fi',range_hint="0 = без звука · 1 = норма · Общая × игрок, до 16×",
  load_world='Загрузите мир, чтобы настроить голоса.',waiting_voice='Ожидание голосового чата.',
  voice_error='Не удалось изменить громкость. Сообщите об ошибке мода.',controls_error='Настройки недоступны. Сообщите об ошибке мода.',
  report_saved='Диагностика сохранена. Добавьте шаги воспроизведения на GitHub.',report_failed='Не удалось сохранить диагностику. В отчёте есть краткая сводка.',
  ready='Настройте голоса: Esc → Управление игроками, или F8.',
  native_master="Все голоса",native_voice="Голос",
  native_report='ОШИБКА МОДА',native_support='ПОДДЕРЖАТЬ · KO-FI',
  reset="Сброс",
  effective="Итог %.2f×: общая %.2f× × игрок %.2f×",
 },
 ja={
  voice_title='ボイスチャット音量',master='全体のボイス音量',
  players_title='プレイヤー別の音量',no_players='他のプレイヤーは接続していません。',
  report='MODの不具合を報告',support='Ko-fiで支援',range_hint="0 = 消音 · 1 = 標準 · 全体 × 個別、最大16×",
  load_world='ワールドを読み込むと音量を調整できます。',waiting_voice='ボイスチャットを待機中。',
  voice_error='音量の変更に失敗しました。不具合を報告してください。',controls_error='操作できません。不具合を報告してください。',
  report_saved='診断データを保存しました。GitHubに再現手順を記入してください。',report_failed='診断データを保存できませんでした。報告には概要が含まれます。',
  ready='Esc → プレイヤー管理、またはF8で音量を調整できます。',
  native_master="すべてのボイス",native_voice="ボイス",
  native_report='MODの不具合を報告',native_support='支援 · KO-FI',
  reset="リセット",
  effective="実効音量 %.2f×：全体 %.2f× × 個別 %.2f×",
 },
 ['zh-Hans']={
  voice_title='语音聊天音量',master='语音总音量',
  players_title='玩家独立音量',no_players='没有其他玩家在线。',
  report='报告模组问题',support='通过 Ko-fi 支持',range_hint="0 = 静音 · 1 = 默认 · 总音量 × 玩家音量，最高16×",
  load_world='进入世界后可调整语音音量。',waiting_voice='正在等待语音聊天。',
  voice_error='语音音量调整失败，请报告模组问题。',controls_error='控件不可用，请报告模组问题。',
  report_saved='诊断数据已保存，请在 GitHub 中补充复现步骤。',report_failed='无法保存诊断数据，问题报告中包含摘要。',
  ready='在 Esc → 玩家管理中调整语音，或按 F8。',
  native_master="所有语音",native_voice="语音",
  native_report='报告模组问题',native_support='支持 · KO-FI',
  reset="重置",
  effective="实际音量 %.2f×：总音量 %.2f× × 玩家 %.2f×",
 },
 ['zh-Hant']={
  voice_title='語音聊天音量',master='語音總音量',
  players_title='玩家個別音量',no_players='沒有其他玩家在線。',
  report='回報模組問題',support='透過 Ko-fi 支持',range_hint="0 = 靜音 · 1 = 預設 · 總音量 × 玩家音量，最高16×",
  load_world='進入世界後可調整語音音量。',waiting_voice='正在等待語音聊天。',
  voice_error='語音音量調整失敗，請回報模組問題。',controls_error='控制項無法使用，請回報模組問題。',
  report_saved='診斷資料已儲存，請在 GitHub 補充重現步驟。',report_failed='無法儲存診斷資料，問題回報中包含摘要。',
  ready='在 Esc → 玩家管理中調整語音，或按 F8。',
  native_master="所有語音",native_voice="語音",
  native_report='回報模組問題',native_support='支持 · KO-FI',
  reset="重設",
  effective="實際音量 %.2f×：總音量 %.2f× × 玩家 %.2f×",
 },
 es={
  voice_title='Volumen del chat de voz',master='Volumen general de voces',
  players_title='Volumen individual de jugadores',no_players='No hay otros jugadores conectados.',
  report='Reportar error del mod',support='Apoyar en Ko-fi',range_hint="0 = silencio · 1 = normal · General × jugador, hasta 16×",
  load_world='Carga un mundo para ajustar las voces.',waiting_voice='Esperando el chat de voz.',
  voice_error='No se pudo ajustar la voz. Reporta un error del mod.',controls_error='Controles no disponibles. Reporta un error del mod.',
  report_saved='Diagnóstico guardado. Agrega los pasos en GitHub.',report_failed='No se pudo guardar el diagnóstico. El reporte incluye un resumen.',
  ready='Ajusta las voces en Esc → Administrar jugadores, o F8.',
  native_master="Todas las voces",native_voice="Voz",
  native_report='REPORTAR ERROR DEL MOD',native_support='APOYAR · KO-FI',
  reset="Restablecer",
  effective="Volumen efectivo %.2f×: general %.2f× × jugador %.2f×",
 },
}
local M={}
function M.resolve(tag)
    local normalized=tostring(tag or ''):lower():gsub('_','-')
    if normalized:match('^zh') then
        return (normalized:find('hant',1,true) or normalized:match('%-tw') or normalized:match('%-hk') or normalized:match('%-mo')) and 'zh-Hant' or 'zh-Hans'
    end
    local base=normalized:match('^([a-z]+)')
    return messages[base] and base or 'en'
end
function M.new(reader)
    local self={language='en'}
    function self:refresh()
        local ok,tag=pcall(reader)
        if not ok or not tag then return false end
        local language=M.resolve(tag)
        if language==self.language then return false end
        self.language=language
        return true
    end
    function self:t(key,...)
        local value=messages[self.language][key] or assert(messages.en[key],'Unknown translation: '..key)
        return select('#',...)>0 and string.format(value,...) or value
    end
    return self
end
return M
