// js/core/i18n.js
// 多言語（日本語 / 英語）対応の中核。
//  - dict: キー → 文言の辞書（ja / en）
//  - applyI18n(lang): data-i18n 属性を持つ要素へ文言を流し込む
//  - t(key, params): 現在の言語で文言を取得（{name} 形式の差し込みに対応）
//  - initLang(): localStorage から言語を復元して適用
//  - toggleLang(): ja ⇄ en を切替
//
// 設計メモ:
//  - 入力値（select の value 等）は従来どおりで、表示テキストのみ翻訳する。
//  - 検証メッセージ・ツールバーの通知も t() を通して翻訳する。

export const dict = {
  ja: {
    // ---- アプリ全体 / ツールバー ----
    "app.title": "General Settings UI",
    "toolbar.load": "初期値を読み込む",
    "toolbar.loadPre": "前回設定を読み込み",
    "toolbar.save": "現在の設定を保存して設定終了",
    "toolbar.saveAs": "名前を付けて保存…",
    "toolbar.open": "設定ファイルを開く…",

    // ---- 状態テキスト ----
    "status.unselected": "(未選択)",

    // ---- 機体モデル設定 ----
    "model.legend": "機体モデル設定",
    "model.param": "諸元表ファイル (.xlsx)",
    "model.pickParam": "諸元表を選択",
    "model.param1": "1段目 諸元表ファイル (.xlsx)",
    "model.pickParam1": "1段目 諸元表を選択",
    "model.param2": "2段目 分離上部 諸元表ファイル (.xlsx)",
    "model.pickParam2": "2段目(分離上部) 諸元表を選択",
    "model.param3": "2段目 分離下部 諸元表ファイル (.xlsx)",
    "model.pickParam3": "2段目(分離下部) 諸元表を選択",
    "model.thrust": "推力履歴データ (.xlsx/.csv/.txt)",
    "model.pickThrust": "推力履歴を選択",
    "model.descent": "降下モデル",
    "model.descent.note": "降下中の挙動モデルを選択します。",
    "model.descent.vw": "風速モデル",
    "model.descent.dyn": "動力学モデル",
    "model.multi": "多段設定（最大2段）",
    "model.multi.note": "ON にすると2段式として諸元表を3ファイル選択します。",
    "model.multi.off": "オフ（単段）",
    "model.multi.on": "オン（2段式）",

    // ---- 打上げ・風・時間 ----
    "cond.legend": "打上げ・風・時間設定",
    "cond.elev.group": "打上げ仰角（射角）[deg]",
    "cond.vw0.group": "基準高度風速 Vw0 [m/s]",
    "cond.wpsi.group": "風向 Wpsi[deg]",
    "cond.min": "最小",
    "cond.max": "最大",
    "cond.step": "刻み",
    "cond.set.note": "単一条件で計算する場合は「最小=最大, 刻み=1」としてください。",
    "cond.fp": "落下分散図 設定ファイル",
    "cond.pickFP": "落下分散図設定を選択",
    "cond.wind": "風モデル",
    "cond.wind.note": "MSM / CSV を選んだ場合は下の欄でファイルを指定します。",
    "cond.wind.powerlaw": "べき乗則",
    "cond.wind.msm": "MSM（気象データ）",
    "cond.wind.csv": "CSV（風速プロファイル）",
    "cond.msm": "MSM 気象データ (.nc)",
    "cond.pickMsm": "MSMファイルを選択",
    "cond.windcsv": "風速プロファイル CSV (.xlsx/.csv)",
    "cond.pickCsv": "CSVファイルを選択",
    "cond.base": "方位の基準",
    "cond.angle": "角度の回転方向",
    "cond.angle.cw": "時計回り (CW)",
    "cond.angle.ccw": "反時計回り (CCW)",
    "cond.tmax": "最大計算時間 t_max [s]",
    "cond.rate": "計算レート（積分周波数）[Hz]",
    "cond.landing": "着地モード",
    "cond.landing.hard": "弾道（Hard）",
    "cond.landing.descent": "開傘降下（Descent）",
    "cond.landing.both": "両方（Both）",
    "cond.base.ME": "磁方位・東 (ME)",
    "cond.base.MN": "磁方位・北 (MN)",
    "cond.base.MS": "磁方位・南 (MS)",
    "cond.base.MW": "磁方位・西 (MW)",
    "cond.base.TE": "真方位・東 (TE)",
    "cond.base.TN": "真方位・北 (TN)",
    "cond.base.TS": "真方位・南 (TS)",
    "cond.base.TW": "真方位・西 (TW)",

    // ---- ロール制御 ----
    "roll.legend": "ロール制御設定",
    "roll.exec": "ロール制御の実行",
    "roll.exec.on": "実行する",
    "roll.exec.off": "実行しない",
    "roll.func": "制御関数名",
    "roll.simu": "シミュレーションモード",
    "roll.simu.launch": "Launch（打上げ）",
    "roll.simu.rot": "Rotational（定常回転）",
    "roll.va": "対気速度（定常回転時）Va [m/s]",
    "roll.z": "高度（定常回転時）z [m]",
    "roll.factor": "ロールモーメントの指定方法",
    "roll.factor.coef": "ロール空力係数",
    "roll.factor.moment": "モーメント履歴 CSV",
    "roll.cl0": "ロール空力係数 Cl0",
    "roll.mx": "ロールモーメント履歴データ (.xlsx/.csv)",
    "roll.pickMx": "選択",
    "roll.aero": "動翼空力データベース (aero DB)",
    "roll.aero.note": "ON: 最大5個のDBファイルを解析流速ごとに登録（「使用」は2個以上必須・流速は互いに異なる正値）。",
    "roll.aero.off": "使用しない",
    "roll.aero.on": "使用する",
    "roll.aero.use": "使用",
    "roll.aero.v": "解析流速 v [m/s]",
    "roll.comp": "パーツ別空力寄与モード (実効舵角)",
    "roll.comp.note": "ON: 各部品の CN_α・X_cp・取付角を記した Excel(Components シート)を読み込み、動翼の実効迎角 α+δ をピッチ/ヨーに反映します。ロールは従来通り。",
    "roll.comp.off": "使用しない",
    "roll.comp.on": "使用する",
    "roll.comp.delta": "固定動翼角 δ_fixed [deg]",
    "roll.comp.file": "パーツ別空力データ (.xlsx)",
    "roll.comp.pick": "選択",
    "roll.comp.fix": "固定舵角モード",
    "roll.comp.fix.off": "使用しない",
    "roll.comp.fix.on": "使用する",
    "roll.comp.fix.note": "ON: 制御関数なしで全動翼を δ_fixed に固定（制御関数を併用する場合は制御舵角 δ_a と重畳）。",
    "roll.pickAero1": "DB#1 を選択",
    "roll.pickAero2": "DB#2 を選択",
    "roll.pickAero3": "DB#3 を選択",
    "roll.pickAero4": "DB#4 を選択",
    "roll.pickAero5": "DB#5 を選択",

    // ---- オプション ----
    "option.legend": "オプション設定",
    "option.parallel": "並列計算（Parallel computing）",
    "option.parallel.yes": "有効",
    "option.parallel.no": "無効",

    // ---- 出力 ----
    "output.legend": "結果出力設定",
    "output.modeExport": "出力先モード",
    "output.modeExport.default": "自動（default）",
    "output.modeExport.manual": "手動指定（manual）",
    "output.pickResultDir": "出力先を選択…",
    "output.data": "出力ログデータ",
    "output.data.none": "なし",
    "output.data.timelog": "時系列ログ (vs-time)",
    "output.data.feature": "特徴値 (FeatureValues)",
    "output.figs": "出力する図",
    "output.figs.note": "出力する図・ファイルを選択してください。",
    "output.fig.flightpath": "飛行経路図 (JPG)",
    "output.fig.kmlflight": "飛行経路 KML",
    "output.fig.fallpoint": "落下分散図 (JPG)",
    "output.fig.kmlfall": "落下分散 KML",
    "output.fig.mp4": "姿勢変化 MP4",
    "output.fig.wind": "風プロファイル図 (JPG)",
    "output.fig.windcsv": "上空風モデル CSV (PowerLaw時のみ)",

    // ---- i ボタン（仕様説明） ----
    "info.descent": "降下フェーズの落下挙動モデル。風速モデルは終端速度＋風の移流、動力学モデルはパラシュート空気力を解いて計算します。",
    "info.multi": "ON にすると2段式として扱い、諸元表を「1段目／2段目分離上部／2段目分離下部」の3ファイル指定します。",
    "info.elev": "ランチャの仰角。鉛直からではなく水平からの角度 [deg]。範囲計算する場合は最小・最大・刻みを指定します。",
    "info.vw0": "基準高度における地表付近の基準風速 [m/s]。べき乗則モデルでは各高度へ補間されます。MSM/CSV 選択時は無効です。",
    "info.wpsi": "風が吹いてくる方位 [deg]。基準方位と回転方向（CW/CCW）は別項目で指定します。MSM/CSV 選択時は無効です。",
    "info.fp": "落下分散図の背景・軸範囲などをまとめた設定ファイル（.mat/.xlsx/.json）。落下点プロットや KML 出力の表示基準に使われます。",
    "info.wind": "風の与え方。べき乗則=パラメトリック、MSM=NetCDF 気象データ、CSV=高度別の風速プロファイル。MSM/CSV では Vw0/風向の掃引は無効になります。",
    "info.base": "方位の基準。磁方位（M）か真方位（T）か、および東西南北のどれを 0deg 基準とするか。内部計算は真方位に統一されます。",
    "info.angle": "風向などの角度を時計回り(CW)で数えるか反時計回り(CCW)で数えるか。射場資料の表記に合わせてください。",
    "info.tmax": "1条件あたりの最大シミュレーション時間 [s]。これを超えると計算を打ち切ります。",
    "info.rate": "数値積分の更新頻度 [Hz]。内部では時間刻み dt = 1/Hz に変換されます。大きいほど高精度・低速。",
    "info.landing": "弾道=パラシュート無しの着弾、開傘降下=パラシュート降下、両方=両モードを各々計算します。",
    "info.simu": "打上げ=通常の打上げ解析、定常回転=指定の対気速度・高度で姿勢一定とした回転解析。",
    "info.factor": "ロールモーメントの与え方。ロール空力係数 Cl0 を使うか、時間履歴のモーメント CSV を使うか。",
    "info.cl0": "ロール方向の空力係数 Cl0。正の小さな値（例: 0.001）を入力します。",
    "info.aero": "動翼の空力データベースを解析流速ごとに登録し、α-δ-V の3次元テーブルとして補間します。使用するファイルは2個以上、各流速は互いに異なる正値にしてください。",
    "info.comp": "各部品の CN_α・X_cp(m)・取付角・可動フラグ・δ符号を記した Excel(Components シート)を読み込み、ピッチ/ヨーの法線力とモーメントを部品ごとに計算します。動翼は実効迎角 α+δ で個別に評価され、圧力中心の α・δ 依存性が自然に表れます。ロールは従来の Mx1(Cl0/Clda) を使用。X_cp の単位はメートルです。",
    "info.comp.fix": "固定舵角モード。ON にすると全動翼を共通の固定動翼角 δ_fixed[deg] に固定します。制御関数（ロール制御）の設定は不要で、ロール制御 OFF でも動作します。制御関数を併用する場合は δ_i = c_fixed·δ_fixed + s_da·δ_a として重畳されます。",
    "info.control_func": "@Roll_control フォルダ内の制御関数名（例: example）。ここで指定した関数がロール制御に使われます。",
    "info.output": "出力するデータ種別。時系列ログ=各時刻の状態量、特徴値=最大高度や最大動圧などの代表値。",

    // ---- 検証メッセージ ----
    "ui.inputError": "入力エラー",
    "err.label.elev": "打上げ仰角",
    "err.label.vw0": "基準高度風速 Vw0",
    "err.label.wpsi": "風向 Wpsi",
    "err.set.nan": "{label}: 最小/最大/刻みは数値で入力してください",
    "err.set.step": "{label}: 刻みは正の数にしてください",
    "err.set.maxmin": "{label}: 最大は最小以上にしてください",
    "err.set.min": "{label}: 最小が {v} 未満です",
    "err.set.max": "{label}: 最大が {v} を超えています",
    "err.tmax": "最大計算時間 t_max は正の数にしてください",
    "err.rate": "計算レート (Hz) は正の数にしてください",
    "err.fp": "落下分散図 設定ファイルが未選択です",
    "err.wind": "風モデルの選択が不正です",
    "err.landing": "着地モードの選択が不正です",
    "err.base": "方位の基準の選択が不正です",
    "err.angle": "角度の回転方向の選択が不正です",
    "err.msm": "MSM 用 .nc ファイルが未選択です",
    "err.windcsv": "風速プロファイル CSV (.xlsx/.csv) が未選択です",
    "err.param.stage1": "1段目 諸元表ファイルが未選択です",
    "err.param.stage2": "2段目(分離上部) 諸元表ファイルが未選択です",
    "err.param.stage3": "2段目(分離下部) 諸元表ファイルが未選択です",
    "err.param": "諸元表ファイルが未選択です",
    "err.thrust": "推力履歴データが未選択です",
    "err.descent": "降下モデルの選択が不正です",
    "err.exec": "ロール制御の実行は「実行する/しない」を選択してください",
    "err.func": "制御関数名を入力してください",
    "err.simu": "シミュレーションモードの選択が不正です",
    "err.factor": "ロールモーメントの指定方法の選択が不正です",
    "err.rot.va": "定常回転条件: Va[m/s] は 0 より大きい数値にしてください",
    "err.rot.z": "定常回転条件: z[m] は 0 以上の数値にしてください",
    "err.cl0": "ロール空力係数の場合: Cl0 は 0 より大きい数値にしてください",
    "err.mx": "モーメント CSV の場合: ロールモーメント履歴データ (.xlsx/.csv) を選択してください",
    "err.aero.count": "動翼空力DB: 使用する場合は「使用」にしたファイルが2つ以上必要です（解析流速 v の補間に使用）",
    "err.aero.fn": "動翼空力DB #{n}: 「使用」ですが DB ファイルが未選択です",
    "err.aero.v": "動翼空力DB #{n}: 解析流速 v[m/s] は 0 より大きい数値にしてください",
    "err.aero.dup": "動翼空力DB: 「使用」にしたファイルの解析流速 v は互いに異なる値にしてください",
    "err.comp.fn": "パーツ別空力: 「使用する」ですが Excel ファイルが未選択です",
    "err.comp.delta": "パーツ別空力: 固定動翼角 δ_fixed[deg] は数値で入力してください",
    "err.parallel": "並列計算の選択が不正です",
    "err.modeexport": "出力先モードの選択が不正です",
    "err.output": "出力ログデータの選択が不正です",

    // ---- ツールバー通知 ----
    "msg.loadFail": "読み込み失敗: {err}",
    "msg.loadOk": "設定を読み込みました（ファイル項目は未選択に戻しています）",
    "msg.preFail": "前回設定の読み込み失敗: {err}",
    "msg.preOk": "前回設定を読み込みました（ファイル/フォルダのパスを含めて反映）",
    "msg.confirmSave": "現在の設定を保存してウィンドウを閉じます。よろしいですか？",
    "msg.saveCancel": "保存と終了をキャンセルしました。",
    "msg.saveFail": "保存に失敗: {err}",
    "msg.openFail": "読み込み失敗: {err}",
    "msg.openOk": "設定を読み込みました: {path}（ファイル項目は未選択に戻しています）",
    "msg.selected": "選択中: {name}",
  },

  en: {
    // ---- App / toolbar ----
    "app.title": "General Settings UI",
    "toolbar.load": "Load defaults",
    "toolbar.loadPre": "Load previous settings",
    "toolbar.save": "Save & close",
    "toolbar.saveAs": "Save as…",
    "toolbar.open": "Open settings file…",

    "status.unselected": "(none)",

    // ---- Model ----
    "model.legend": "Rocket Model Settings",
    "model.param": "Rocket parameter file (.xlsx)",
    "model.pickParam": "Select parameter file",
    "model.param1": "Stage 1 parameter file (.xlsx)",
    "model.pickParam1": "Select stage-1 file",
    "model.param2": "Stage 2 (upper) parameter file (.xlsx)",
    "model.pickParam2": "Select stage-2 (upper) file",
    "model.param3": "Stage 2 (lower) parameter file (.xlsx)",
    "model.pickParam3": "Select stage-2 (lower) file",
    "model.thrust": "Thrust curve data (.xlsx/.csv/.txt)",
    "model.pickThrust": "Select thrust data",
    "model.descent": "Descent model",
    "model.descent.note": "Model used for the descent phase.",
    "model.descent.vw": "Wind-speed model（Vw model）",
    "model.descent.dyn": "Dynamics model",
    "model.multi": "Multi-stage (up to 2 stages)",
    "model.multi.note": "When ON, three parameter files are required for a 2-stage rocket.",
    "model.multi.off": "Off (single stage)",
    "model.multi.on": "On (2-stage)",

    // ---- Launch / Wind / Time ----
    "cond.legend": "Launch / Wind / Time",
    "cond.elev.group": "Launch elevation angle [deg]",
    "cond.vw0.group": "Reference wind speed Vw0 [m/s]",
    "cond.wpsi.group": "Wind direction Wpsi[deg]",
    "cond.min": "Min",
    "cond.max": "Max",
    "cond.step": "Step",
    "cond.set.note": "For a single condition, set min = max and step = 1.",
    "cond.fp": "Fall-point map setting file",
    "cond.pickFP": "Select fall-point setting",
    "cond.wind": "Wind model",
    "cond.wind.note": "When MSM / CSV is selected, specify the file below.",
    "cond.wind.powerlaw": "Power law",
    "cond.wind.msm": "MSM (meteorological data)",
    "cond.wind.csv": "CSV (wind profile)",
    "cond.msm": "MSM meteorological data (.nc)",
    "cond.pickMsm": "Select MSM file",
    "cond.windcsv": "Wind profile CSV (.xlsx/.csv)",
    "cond.pickCsv": "Select CSV file",
    "cond.base": "Azimuth reference",
    "cond.angle": "Angle rotation direction",
    "cond.angle.cw": "Clockwise (CW)",
    "cond.angle.ccw": "Counter-clockwise (CCW)",
    "cond.tmax": "Max simulation time t_max [s]",
    "cond.rate": "Calculation rate (integration freq.) [Hz]",
    "cond.landing": "Landing mode",
    "cond.landing.hard": "Ballistic (impact)",
    "cond.landing.descent": "Parachute descent",
    "cond.landing.both": "Both",
    "cond.base.ME": "Magnetic East (ME)",
    "cond.base.MN": "Magnetic North (MN)",
    "cond.base.MS": "Magnetic South (MS)",
    "cond.base.MW": "Magnetic West (MW)",
    "cond.base.TE": "True East (TE)",
    "cond.base.TN": "True North (TN)",
    "cond.base.TS": "True South (TS)",
    "cond.base.TW": "True West (TW)",

    // ---- Roll control ----
    "roll.legend": "Roll Control",
    "roll.exec": "Execute roll control",
    "roll.exec.on": "Enabled",
    "roll.exec.off": "Disabled",
    "roll.func": "Control function name",
    "roll.simu": "Simulation mode",
    "roll.simu.launch": "Launch",
    "roll.simu.rot": "Rotational (fixed attitude)",
    "roll.va": "Airspeed (rotational) Va [m/s]",
    "roll.z": "Altitude (rotational) z [m]",
    "roll.factor": "Roll moment source",
    "roll.factor.coef": "Roll aero coefficient",
    "roll.factor.moment": "Moment history CSV",
    "roll.cl0": "Roll aero coefficient Cl0",
    "roll.mx": "Rolling moment data (.xlsx/.csv)",
    "roll.pickMx": "Select",
    "roll.aero": "Control-surface aero DB",
    "roll.aero.note": "ON: register up to 5 DB files per analysis airspeed (at least 2 enabled; airspeeds must be distinct positive values).",
    "roll.aero.off": "Do not use",
    "roll.aero.on": "Use",
    "roll.aero.use": "Use",
    "roll.aero.v": "Analysis airspeed v [m/s]",
    "roll.comp": "Per-component aero mode (effective deflection)",
    "roll.comp.note": "ON: load an Excel (Components sheet) listing each part's CN_α / X_cp / mount angle; the control fins' effective AoA α+δ is reflected in pitch/yaw. Roll is unchanged.",
    "roll.comp.off": "Do not use",
    "roll.comp.on": "Use",
    "roll.comp.delta": "Fixed fin angle δ_fixed [deg]",
    "roll.comp.file": "Per-component aero data (.xlsx)",
    "roll.comp.pick": "Select",
    "roll.comp.fix": "Fixed-deflection mode",
    "roll.comp.fix.off": "Do not use",
    "roll.comp.fix.on": "Use",
    "roll.comp.fix.note": "ON: hold all control fins at δ_fixed without a control function (superposed with control deflection δ_a when a control function is also used).",
    "roll.pickAero1": "Select DB#1",
    "roll.pickAero2": "Select DB#2",
    "roll.pickAero3": "Select DB#3",
    "roll.pickAero4": "Select DB#4",
    "roll.pickAero5": "Select DB#5",

    // ---- Options ----
    "option.legend": "Options",
    "option.parallel": "Parallel computing",
    "option.parallel.yes": "Enabled",
    "option.parallel.no": "Disabled",

    // ---- Output ----
    "output.legend": "Output",
    "output.modeExport": "Output destination mode",
    "output.modeExport.default": "Auto (default)",
    "output.modeExport.manual": "Manual",
    "output.pickResultDir": "Select output folder…",
    "output.data": "Output data type",
    "output.data.none": "None",
    "output.data.timelog": "Time-series logs (vs-time)",
    "output.data.feature": "Feature values",
    "output.figs": "Figures to output",
    "output.figs.note": "Select the figures / files to output.",
    "output.fig.flightpath": "Flight path (JPG)",
    "output.fig.kmlflight": "Flight path KML",
    "output.fig.fallpoint": "Fall-point map (JPG)",
    "output.fig.kmlfall": "Fall-point KML",
    "output.fig.mp4": "Attitude MP4",
    "output.fig.wind": "Wind profile (JPG)",
    "output.fig.windcsv": "Upper-wind CSV (PowerLaw only)",

    // ---- Info ----
    "info.descent": "Falling-behavior model during descent. Wind-speed model uses terminal velocity + wind advection; dynamics model solves parachute aerodynamics.",
    "info.multi": "When ON the rocket is treated as 2-stage: specify three parameter files (stage 1 / stage 2 upper / stage 2 lower).",
    "info.elev": "Launcher elevation angle measured from the horizontal [deg]. For a sweep, specify min, max and step.",
    "info.vw0": "Reference near-ground wind speed [m/s] at the reference altitude; extrapolated per altitude by the power law. Disabled for MSM/CSV.",
    "info.wpsi": "Direction the wind blows from [deg]. The reference azimuth and rotation (CW/CCW) are set separately. Disabled for MSM/CSV.",
    "info.fp": "Setting file (.mat/.xlsx/.json) holding the fall-point map background and axis ranges; used as display reference for fall-point plots and KML.",
    "info.wind": "How wind is supplied. Power law = parametric, MSM = NetCDF data, CSV = altitude wind profile. MSM/CSV disable the Vw0/direction sweep.",
    "info.base": "Azimuth reference: magnetic (M) or true (T), and which cardinal direction is the 0deg base. Internal calculation is unified to true azimuth.",
    "info.angle": "Whether angles such as wind direction are counted clockwise (CW) or counter-clockwise (CCW). Match your launch-site documents.",
    "info.tmax": "Maximum simulation time per condition [s]; the run stops beyond this.",
    "info.rate": "Numerical integration update frequency [Hz]; internally converted to time step dt = 1/Hz. Higher = more accurate, slower.",
    "info.landing": "Ballistic = impact without parachute, Descent = parachute descent, Both = compute each mode.",
    "info.simu": "Launch = normal launch analysis; Rotational = fixed-attitude rotation analysis at a given airspeed and altitude.",
    "info.factor": "How the roll moment is supplied: a roll aero coefficient Cl0, or a time-history moment CSV.",
    "info.cl0": "Roll-axis aerodynamic coefficient Cl0. Enter a small positive value (e.g. 0.001).",
    "info.aero": "Register control-surface aero DBs per analysis airspeed and interpolate as an α-δ-V 3D table. At least 2 enabled files; airspeeds must be distinct positive values.",
    "info.comp": "Load an Excel (Components sheet) with each part's CN_α / X_cp(m) / mount angle / movable flag / δ signs, and compute pitch/yaw normal force and moment per part. Control fins are evaluated individually at effective AoA α+δ, so the center of pressure's α/δ dependence emerges naturally. Roll keeps using the existing Mx1 (Cl0/Clda). X_cp is in meters.",
    "info.comp.fix": "Fixed-deflection mode. When ON, all control fins are held at a common fixed angle δ_fixed[deg]. No control function is required; it works even with roll control OFF. If a control function is also used, deflections superpose as δ_i = c_fixed·δ_fixed + s_da·δ_a.",
    "info.control_func": "Name of a control function in the @Roll_control folder (e.g. example); used for roll control.",
    "info.output": "Type of data to export. Time-series logs = state quantities at each time; feature values = representative values such as max altitude and max dynamic pressure.",

    // ---- Validation ----
    "ui.inputError": "Input error",
    "err.label.elev": "Launch elevation",
    "err.label.vw0": "Reference wind speed Vw0",
    "err.label.wpsi": "Wind direction",
    "err.set.nan": "{label}: min/max/step must be numbers",
    "err.set.step": "{label}: step must be positive",
    "err.set.maxmin": "{label}: max must be >= min",
    "err.set.min": "{label}: min is below {v}",
    "err.set.max": "{label}: max exceeds {v}",
    "err.tmax": "Max simulation time t_max must be positive",
    "err.rate": "Calculation rate (Hz) must be positive",
    "err.fp": "Fall-point setting file is not selected",
    "err.wind": "Wind model selection is invalid",
    "err.landing": "Landing mode selection is invalid",
    "err.base": "Azimuth reference selection is invalid",
    "err.angle": "Angle rotation direction selection is invalid",
    "err.msm": "MSM .nc file is not selected",
    "err.windcsv": "Wind profile CSV (.xlsx/.csv) is not selected",
    "err.param.stage1": "Stage 1 parameter file is not selected",
    "err.param.stage2": "Stage 2 (upper) parameter file is not selected",
    "err.param.stage3": "Stage 2 (lower) parameter file is not selected",
    "err.param": "Parameter file is not selected",
    "err.thrust": "Thrust data is not selected",
    "err.descent": "Descent model selection is invalid",
    "err.exec": "Please choose whether to execute roll control",
    "err.func": "Please enter a control function name",
    "err.simu": "Simulation mode selection is invalid",
    "err.factor": "Roll moment source selection is invalid",
    "err.rot.va": "Rotational condition: Va[m/s] must be greater than 0",
    "err.rot.z": "Rotational condition: z[m] must be >= 0",
    "err.cl0": "Coefficient mode: Cl0 must be greater than 0",
    "err.mx": "Moment CSV mode: select a rolling moment data file (.xlsx/.csv)",
    "err.aero.count": "Aero DB: at least 2 files must be enabled when using it (for airspeed v interpolation)",
    "err.aero.fn": "Aero DB #{n}: enabled but the DB file is not selected",
    "err.aero.v": "Aero DB #{n}: analysis airspeed v[m/s] must be greater than 0",
    "err.aero.dup": "Aero DB: analysis airspeed v of enabled files must be distinct",
    "err.comp.fn": "Per-component aero: enabled but the Excel file is not selected",
    "err.comp.delta": "Per-component aero: fixed fin angle δ_fixed[deg] must be a number",
    "err.parallel": "Parallel computing selection is invalid",
    "err.modeexport": "Output destination mode selection is invalid",
    "err.output": "Output data type selection is invalid",

    // ---- Toolbar messages ----
    "msg.loadFail": "Load failed: {err}",
    "msg.loadOk": "Settings loaded (file items reset to unselected).",
    "msg.preFail": "Failed to load previous settings: {err}",
    "msg.preOk": "Previous settings loaded (including file/folder paths).",
    "msg.confirmSave": "Save the current settings and close the window. Continue?",
    "msg.saveCancel": "Save & close cancelled.",
    "msg.saveFail": "Save failed: {err}",
    "msg.openFail": "Load failed: {err}",
    "msg.openOk": "Settings loaded: {path} (file items reset to unselected).",
    "msg.selected": "Selected: {name}",
  },
};

let currentLang = "ja";

export function getLang() {
  return currentLang;
}

export function t(key, params) {
  let s = dict[currentLang]?.[key] ?? dict.ja?.[key] ?? key;
  if (params) {
    for (const k of Object.keys(params)) {
      s = s.split(`{${k}}`).join(String(params[k]));
    }
  }
  return s;
}

export function applyI18n(lang) {
  currentLang = (lang === "en") ? "en" : "ja";

  document.querySelectorAll("[data-i18n]").forEach((el) => {
    const key = el.getAttribute("data-i18n");
    const txt = dict[currentLang]?.[key];
    if (txt == null && !dict.ja?.[key]) {
      // 辞書漏れの検知（開発時に気付けるよう警告）
      console.warn(`[i18n] missing key: ${key}`);
      return;
    }
    el.textContent = t(key);
  });

  // 言語トグルには「切替先の言語名」を表示する
  const tg = document.getElementById("langToggle");
  if (tg) tg.textContent = (currentLang === "ja") ? "English" : "日本語";

  document.documentElement.lang = currentLang;
  try { localStorage.setItem("ui_lang", currentLang); } catch (_) { /* noop */ }
}

export function initLang() {
  let lang = "ja";
  try { lang = localStorage.getItem("ui_lang") || "ja"; } catch (_) { /* noop */ }
  applyI18n(lang);
  return currentLang;
}

export function toggleLang() {
  applyI18n(currentLang === "ja" ? "en" : "ja");
  return currentLang;
}
