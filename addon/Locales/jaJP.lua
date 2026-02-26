------------------------------------------------------------------------
-- RotaAssist - 日本語ローカライズ
-- Japanese locale using WoW JP server player conventions.
-- スキル (skill), クールダウン (cooldown), ローテーション (rotation), スペック (spec)
------------------------------------------------------------------------

local L = LibStub("AceLocale-3.0"):NewLocale("RotaAssist", "jaJP")
if not L then return end

------------------------------------------------------------------------
-- 一般
------------------------------------------------------------------------
L["STARTUP_MESSAGE"]    = "RotaAssist v%s がロードされました。/ra でヘルプを表示。"
L["UNKNOWN_COMMAND"]    = "不明なコマンド: %s — /ra help でヘルプを表示"

------------------------------------------------------------------------
-- スラッシュコマンドヘルプ
------------------------------------------------------------------------
L["SLASH_HELP_HEADER"]  = "RotaAssist コマンド一覧:"
L["SLASH_HELP_CONFIG"]  = "設定パネルを開く"
L["SLASH_HELP_TOGGLE"]  = "表示の切り替え"
L["SLASH_HELP_LOCK"]    = "表示位置のロック/解除"
L["SLASH_HELP_RESET"]   = "全設定をリセット"
L["SLASH_HELP_DEBUG"]   = "デバッグモード切り替え"
L["SLASH_HELP_VERSION"] = "バージョン情報を表示"

------------------------------------------------------------------------
-- 設定 / コンフィグパネル
------------------------------------------------------------------------
L["CONFIG_NOT_LOADED"]  = "設定パネルはまだ読み込まれていません。"
L["SETTINGS_RESET"]     = "全ての設定がデフォルトにリセットされました。"
L["DEBUG_ENABLED"]      = "デバッグモード: オン"
L["DEBUG_DISABLED"]     = "デバッグモード: オフ"

L["CONFIG_HEADER_GENERAL"]    = "一般"
L["CONFIG_HEADER_DISPLAY"]    = "表示"
L["CONFIG_HEADER_COOLDOWNS"]  = "クールダウン"
L["CONFIG_HEADER_ABOUT"]      = "情報"

L["CONFIG_ENABLED"]           = "RotaAssist を有効化"
L["CONFIG_ENABLED_DESC"]      = "アドオンのオン/オフを切り替えます。"
L["CONFIG_LANGUAGE"]          = "言語"
L["CONFIG_LANGUAGE_DESC"]     = "表示言語を選択（/reload が必要です）。"
L["CONFIG_DEBUG"]             = "デバッグモード"
L["CONFIG_DEBUG_DESC"]        = "チャットにデバッグメッセージを表示します。"
L["CONFIG_MINIMAP"]           = "ミニマップボタンを表示"
L["CONFIG_MINIMAP_DESC"]      = "ミニマップアイコンの表示を切り替えます。"

L["CONFIG_ICON_COUNT"]        = "アイコン数"
L["CONFIG_ICON_COUNT_DESC"]   = "予測スキルアイコンの表示数 (1-5)。"
L["CONFIG_SCALE"]             = "スケール"
L["CONFIG_SCALE_DESC"]        = "全体の表示倍率 (50% - 200%)。"
L["CONFIG_ALPHA"]             = "不透明度"
L["CONFIG_ALPHA_DESC"]        = "表示の不透明度 (10% - 100%)。"
L["CONFIG_LOCK"]              = "位置をロック"
L["CONFIG_LOCK_DESC"]         = "表示フレームのドラッグを無効にします。"
L["CONFIG_SHOW_OOC"]          = "非戦闘時も表示"
L["CONFIG_SHOW_OOC_DESC"]     = "戦闘外でも表示を維持します。"
L["CONFIG_FADE_OOC"]          = "非戦闘時にフェードアウト"
L["CONFIG_FADE_OOC_DESC"]     = "戦闘外で透明度を下げます。"
L["CONFIG_KEYBINDS"]          = "キーバインド表示"
L["CONFIG_KEYBINDS_DESC"]     = "アイコンにキーバインドテキストを表示します。"
L["CONFIG_COOLDOWN_SWIRL"]    = "クールダウンスパイラル表示"
L["CONFIG_COOLDOWN_SWIRL_DESC"] = "アイコンにクールダウン回転アニメーションを表示します。"

L["CONFIG_CD_ENABLED"]        = "クールダウンパネルを有効化"
L["CONFIG_CD_ENABLED_DESC"]   = "大技クールダウントラッキングバーを表示します。"
L["CONFIG_CD_SCALE"]          = "クールダウンパネルスケール"
L["CONFIG_CD_SCALE_DESC"]     = "クールダウントラッキングバーのサイズ (50% - 200%)。"
L["CONFIG_CD_LOCK"]           = "クールダウンパネルをロック"
L["CONFIG_CD_LOCK_DESC"]      = "クールダウンパネルのドラッグを無効にします。"

------------------------------------------------------------------------
-- 表示 / UI
------------------------------------------------------------------------
L["DISPLAY_LOCKED"]           = "表示がロックされました。"
L["DISPLAY_UNLOCKED"]         = "表示がアンロックされました。ドラッグで移動できます。"
L["DISPLAY_ENABLED"]          = "ローテーションアシストを表示中。"
L["DISPLAY_DISABLED"]         = "ローテーションアシストを非表示にしました。"

-- 右クリックメニュー (MainDisplay)
L["LOCK_POSITION"]            = "位置をロック"
L["UNLOCK_POSITION"]          = "位置をアンロック"
L["COMBAT_ONLY_TOOLTIP"]      = "戦闘中のみ表示"
L["OPTIONS"]                  = "オプション"

-- 戦闘前パネル (PrePullPanel ウィジェット)
L["PREPULL_CHECKLIST"]        = "戦闘前チェックリスト"
L["MISSING_ITEMS"]            = "%d 項目が不足"

------------------------------------------------------------------------
-- クールダウントラッカー
------------------------------------------------------------------------
L["CD_READY"]                 = "使用可能"
L["CD_SECONDS"]               = "%d秒"
L["CD_MINUTES"]               = "%d:%02d"

------------------------------------------------------------------------
-- ツールチップ
------------------------------------------------------------------------
L["TOOLTIP_SOURCE_BLIZZARD"]  = "ソース: Blizzardのおすすめ"
L["TOOLTIP_SOURCE_APL"]       = "ソース: APL予測"
L["TOOLTIP_SOURCE_COOLDOWN"]  = "ソース: クールダウン完了"
L["TOOLTIP_CONFIDENCE"]       = "信頼度: %d%%"
L["TOOLTIP_KEYBIND"]          = "キーバインド: %s"
L["TOOLTIP_COOLDOWN"]         = "クールダウン: %s"
L["TOOLTIP_DRAG_HINT"]        = "左クリックでドラッグ。右クリックでオプション。"
L["TOOLTIP_MINIMAP_LEFT"]     = "左クリック: 設定を開く"
L["TOOLTIP_MINIMAP_RIGHT"]    = "右クリック: 表示切り替え"

------------------------------------------------------------------------
-- 情報
------------------------------------------------------------------------
L["ABOUT_DESCRIPTION"]        = "RotaAssist は WoW Midnight (12.0) 向けのインテリジェント戦闘アシスタントです。Hekili の代替として多言語対応。"
L["ABOUT_VERSION"]            = "バージョン: %s"
L["ABOUT_AUTHOR"]             = "作者: RotaAssist チーム"
L["ABOUT_LICENSE"]            = "ライセンス: MIT"
L["ABOUT_WEBSITE"]            = "ウェブサイト: github.com/yourname/rotaassist"

------------------------------------------------------------------------
-- スペック検出
------------------------------------------------------------------------
L["SPEC_DETECTED"]            = "検出: %s %s (%s)"
L["SPEC_NO_APL"]              = "現在のスペックのAPLデータが見つかりません。"
L["SPEC_APL_LOADED"]          = "%s のAPLが読み込まれました。"

------------------------------------------------------------------------
-- デーモンハンター (Demon Hunter)
------------------------------------------------------------------------
-- スペック (Specs)
L["spec_havoc"]               = "ハボック"
L["spec_vengeance"]           = "ヴェンジャンス"
L["spec_devourer"]            = "デヴァウラー"

-- 英雄タレント (Hero Talents)
L["hero_aldrachi_reaver"]     = "アルドラキ・リーバー"
L["hero_fel_scarred"]         = "フェルスカード"
L["hero_annihilator"]         = "アナイアレーター"
L["hero_void_scarred"]        = "ヴォイドスカード"

-- スキル (Abilities)
L["EYE_BEAM"]                 = "アイビーム"
L["BLADE_DANCE"]              = "ブレードダンス"
L["DEATH_SWEEP"]              = "デススウィープ"
L["METAMORPHOSIS"]            = "メタモルフォーシス"
L["THE_HUNT"]                 = "ザ・ハント"
L["VENGEFUL_RETREAT"]         = "ヴェンジフルリトリート"
L["ESSENCE_BREAK"]            = "エッセンスブレイク"
L["GLAIVE_TEMPEST"]           = "グレイヴテンペスト"
L["IMMOLATION_AURA"]          = "イモレーション・オーラ"
L["FELBLADE"]                 = "フェルブレード"
L["FEL_RUSH"]                 = "フェルラッシュ"
L["CHAOS_STRIKE"]             = "ケイオスストライク"
L["ANNIHILATION"]             = "アナイアレーション"
L["FIERY_BRAND"]              = "ファイアリーブランド"
L["FEL_DEVASTATION"]          = "フェルデヴァステーション"
L["SPIRIT_BOMB"]              = "スピリットボム"
L["SOUL_CARVER"]              = "ソウルカーバー"
L["SIGIL_OF_FLAME"]           = "シジル・オブ・フレイム"
L["FRACTURE"]                 = "フラクチャー"
L["SHEAR"]                    = "シアー"
L["VOID_METAMORPHOSIS"]       = "ヴォイドメタモルフォーシス"
L["VOID_RAY"]                 = "ヴォイドレイ"
L["COLLAPSING_STAR"]          = "コラプシングスター"
L["CONSUME"]                  = "コンシューム"
L["DEVOUR"]                   = "デヴァウア"
L["REAP"]                     = "リープ"
L["CULL"]                     = "カル"
L["VOIDBLADE"]                = "ヴォイドブレード"
L["SOUL_IMMOLATION"]          = "ソウルイモレーション"
L["SHIFT"]                    = "シフト"

-- ヒント (Hints)
L["HINT_EYE_BEAM_DEMONIC"]    = "アイビームでデモニック形態に入る"
L["HINT_VOID_RAY_FURY"]       = "フューリー100でヴォイドレイ"
L["HINT_COLLAPSING_STAR"]     = "ソウル30以上でコラプシングスター"
L["HINT_REAP_STACKS"]         = "ヴォイドフォール3スタックでリープ"

------------------------------------------------------------------------
-- ローグ (Rogue)
------------------------------------------------------------------------
L["spec_subtlety"]            = "サブテリティ"
L["SHADOW_DANCE"]             = "シャドウダンス"
L["SYMBOLS_OF_DEATH"]         = "シンボル・オブ・デス"
L["SECRET_TECHNIQUE"]         = "シークレットテクニック"
L["SHADOW_BLADES"]            = "シャドウブレード"
L["SHADOWSTRIKE"]             = "シャドウストライク"
L["BACKSTAB"]                 = "バックスタブ"
L["EVISCERATE"]               = "エヴィセレート"
L["BLACK_POWDER"]             = "ブラックパウダー"
L["RUPTURE"]                  = "ラプチャー"

------------------------------------------------------------------------
-- シャーマン (Shaman)
------------------------------------------------------------------------
L["spec_elemental"]           = "エレメンタル"
L["STORMKEEPER"]              = "ストームキーパー"
L["FIRE_ELEMENTAL"]           = "ファイアエレメンタル"
L["LAVA_BURST"]               = "ラヴァバースト"
L["LIGHTNING_BOLT"]           = "ライトニングボルト"
L["CHAIN_LIGHTNING"]          = "チェーンライトニング"
L["EARTH_SHOCK"]              = "アースショック"
L["EARTHQUAKE"]               = "アースクエイク"
L["FLAME_SHOCK"]              = "フレイムショック"
L["ICEFURY"]                  = "アイスフューリー"

------------------------------------------------------------------------
-- ドルイド (Druid)
------------------------------------------------------------------------
L["spec_balance"]             = "バランス"
L["CELESTIAL_ALIGNMENT"]      = "セレスティアル・アライメント"
L["INCARNATION"]              = "インカーネーション"
L["STARSURGE"]                = "スターサージ"
L["STARFALL"]                 = "スターフォール"
L["WRATH"]                    = "ラース"
L["STARFIRE"]                 = "スターファイア"
L["MOONFIRE"]                 = "ムーンファイア"
L["SUNFIRE"]                  = "サンファイア"
L["STELLAR_FLARE"]            = "ステラフレア"

------------------------------------------------------------------------
L["BURST_SOON_POOL_RESOURCE"] = "バーストまで %d 秒 — リソースを温存！"
L["BURST_READY"]              = "バースト準備完了！"
L["AOE_DETECTED"]             = "%d ターゲット検出 — 範囲モード"
L["DEATH_SWEEP_NOTE"]         = "Death Sweep は Meta中の Blade Dance です"
L["RESOURCE_CAPPING"]         = "リソース溢れ注意！消費して！"

-- Combat Phases
L["PREPULL"]                  = "プリプル"
L["OPENER"]                   = "オープナー"
L["NORMAL"]                   = "通常"
L["AOE"]                      = "範囲"
L["BURST_PREPARE"]            = "バースト準備"
L["BURST_ACTIVE"]             = "バースト!"
L["BURST_COOLDOWN"]           = "クールダウン"
L["RESOURCE_STARVED"]         = "リソース不足"
L["RESOURCE_CAP"]             = "キャップ!"
L["EXECUTE"]                  = "処刑"
L["EMERGENCY"]                = "危険!"

-- UI Toggles & Metrics
L["SHOW_ACCURACY_METER"]      = "精度メーターを表示"
L["SHOW_PHASE_INDICATOR"]     = "フェーズ表示"
L["ACCURACY"]                 = "精度"
L["BLIZZARD_ACCURACY"]        = "Blizzard推奨精度"
L["SMART_ACCURACY"]           = "スマート精度"

------------------------------------------------------------------------
L["BURST_SOON_POOL_RESOURCE"] = "%d秒後にバースト — リソースを温存！"
L["BURST_READY"]              = "バースト準備完了！"
L["AOE_DETECTED"]             = "%d ターゲット — AoE モード"
L["DEATH_SWEEP_NOTE"]         = "デススウィープ = メタ版ブレードダンス"
L["RESOURCE_CAPPING"]         = "リソースが溢れます！消費して！"

