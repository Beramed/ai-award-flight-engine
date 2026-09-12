extends Node
## Fonte da verdade: fases, falas, arenas, spawns e eventos.

enum Speaker { SAMURAI, KIKO, JARBAS, JULIANA, FERNANDA, RAQUEL, NARRATOR }

const TITULO := "Kiko: Wild Fury - Matajava"

const SPEAKER_NAME := {
	Speaker.SAMURAI: "Samurai Caçador",
	Speaker.KIKO: "Kiko",
	Speaker.JARBAS: "Doutor Jarbas",
	Speaker.JULIANA: "Juliana",
	Speaker.FERNANDA: "Fernanda",
	Speaker.RAQUEL: "Raquel",
	Speaker.NARRATOR: "",
}

const INIMIGOS := {
	"javali_corredor": {
		"hp": 3, "speed": 70.0, "touch": 1, "score": 100,
		"kind": "runner", "melee_range": 22.0, "scale": 0.9,
	},
	"javali_saltador": {
		"hp": 3, "speed": 55.0, "touch": 1, "score": 150,
		"kind": "jumper", "melee_range": 22.0, "scale": 0.85,
	},
	"javali_blindado": {
		"hp": 8, "speed": 40.0, "touch": 1, "score": 250,
		"kind": "armored", "melee_range": 26.0, "scale": 1.05, "armor": true,
	},
	"bufalo_lamacal": {
		"hp": 10, "speed": 80.0, "touch": 1, "score": 300,
		"kind": "ambush", "melee_range": 30.0, "scale": 1.2,
	},
	"mae_javali": {
		"hp": 80, "speed": 95.0, "touch": 2, "score": 5000,
		"kind": "boss", "melee_range": 40.0, "scale": 1.7,
	},
}

const FASES := {
	1: {
		"id": "fazenda",
		"nome": "A Fazenda Tomada",
		"estilo": "side_scroll",
		"ambientacao": "Celeiros em chamas e milharais à noite sob chuva fina.",
		"largura": 5600.0,
		"chao_y": 236.0,
		"player_start": Vector2(72, 200),
		"camera_limit_right": 5600.0,
		"chefe": "mae_javali",
		"dialogos": {
			"intro": [
				{"who": Speaker.SAMURAI, "text": "Kiko, a mutação começou aqui. Os javalis locais foram os primeiros a surtar. Limpe a área e destrua a Matriarca!"},
				{"who": Speaker.KIKO, "text": "Horário do banquete. Vou transformar esses porcos em bacon!"},
			],
			"juliana": [
				{"who": Speaker.JULIANA, "text": "Pai! Pegue esta caixa — tem um fuzil dentro!"},
				{"who": Speaker.KIKO, "text": "Fica atrás de mim, Ju. O bacon ainda não acabou."},
			],
			"fernanda": [
				{"who": Speaker.FERNANDA, "text": "Trouxe munição e moedas. Não pare, pai!"},
				{"who": Speaker.KIKO, "text": "Essa é minha garota."},
			],
			"raquel": [
				{"who": Speaker.RAQUEL, "text": "Kiko... eu sabia que você viria."},
				{"who": Speaker.KIKO, "text": "Ninguém toca na minha família. Vou acabar com a Matriarca."},
			],
			"chefe": [
				{"who": Speaker.SAMURAI, "text": "A Matriarca está no celeiro final. Não deixe ela destruir o que restou da fazenda!"},
				{"who": Speaker.KIKO, "text": "GO!"},
			],
			"vitoria": [
				{"who": Speaker.KIKO, "text": "Fazenda limpa. Próxima parada: Amazônia."},
				{"who": Speaker.SAMURAI, "text": "Bom trabalho, caçador. Reabasteça na loja e siga em frente."},
			],
		},
		"props": [
			{"tipo": "celeiro", "x": 260},
			{"tipo": "milho", "x": 430, "w": 220},
			{"tipo": "cerca", "x": 700, "w": 160},
			{"tipo": "celeiro_fogo", "x": 980},
			{"tipo": "silo", "x": 1680},
			{"tipo": "milho", "x": 1880, "w": 280},
			{"tipo": "plataforma", "x": 1980, "y": 196, "w": 160},
			{"tipo": "plataforma", "x": 2180, "y": 176, "w": 120},
			{"tipo": "cerca", "x": 2460, "w": 200},
			{"tipo": "celeiro", "x": 2780},
			{"tipo": "milho", "x": 3300, "w": 260},
			{"tipo": "plataforma", "x": 3480, "y": 196, "w": 140},
			{"tipo": "celeiro_fogo", "x": 3920},
			{"tipo": "silo", "x": 4300},
			{"tipo": "celeiro", "x": 4720},
		],
		"caixas": [
			{"x": 520, "loot": "moedas"},
			{"x": 1240, "loot": "fuzil"},
			{"x": 2100, "loot": "granadas"},
			{"x": 3020, "loot": "doze"},
			{"x": 3680, "loot": "kit"},
		],
		"eventos": [
			{"id": "intro", "tipo": "dialogo", "chave": "intro", "quando": "start"},
			{"id": "wave_entrada", "tipo": "spawn", "quando": "x", "x": 340,
				"inimigos": [
					{"id": "javali_corredor", "x": 520, "facing": -1},
					{"id": "javali_corredor", "x": 610, "facing": -1},
					{"id": "javali_corredor", "x": 700, "facing": -1},
				]},
			{"id": "arena_curral", "tipo": "arena", "quando": "x", "x": 880,
				"left": 880, "right": 1360,
				"ondas": [
					[
						{"id": "javali_corredor", "x": 1280, "facing": -1},
						{"id": "javali_corredor", "x": 920, "facing": 1},
						{"id": "javali_saltador", "x": 1180, "facing": -1},
					],
					[
						{"id": "javali_corredor", "x": 1300, "facing": -1},
						{"id": "javali_corredor", "x": 1260, "facing": -1},
						{"id": "javali_blindado", "x": 1320, "facing": -1},
					],
				]},
			{"id": "resgate_ju", "tipo": "resgate", "quando": "x", "x": 1540,
				"quem": "juliana", "chave": "juliana", "bonus": "fuzil"},
			{"id": "wave_milharal", "tipo": "spawn", "quando": "x", "x": 1760,
				"inimigos": [
					{"id": "javali_saltador", "x": 1980, "facing": -1},
					{"id": "javali_saltador", "x": 2180, "facing": -1},
					{"id": "javali_corredor", "x": 2300, "facing": -1},
				]},
			{"id": "arena_celeiro", "tipo": "arena", "quando": "x", "x": 2520,
				"left": 2520, "right": 3080,
				"ondas": [
					[
						{"id": "javali_blindado", "x": 3000, "facing": -1},
						{"id": "javali_corredor", "x": 2580, "facing": 1},
						{"id": "javali_corredor", "x": 2960, "facing": -1},
					],
					[
						{"id": "javali_saltador", "x": 2700, "facing": 1},
						{"id": "javali_saltador", "x": 2900, "facing": -1},
						{"id": "javali_blindado", "x": 3040, "facing": -1},
						{"id": "javali_corredor", "x": 2560, "facing": 1},
					],
				]},
			{"id": "resgate_fe", "tipo": "resgate", "quando": "x", "x": 3220,
				"quem": "fernanda", "chave": "fernanda", "bonus": "municao"},
			{"id": "wave_final", "tipo": "spawn", "quando": "x", "x": 3380,
				"inimigos": [
					{"id": "javali_corredor", "x": 3560, "facing": -1},
					{"id": "javali_corredor", "x": 3680, "facing": -1},
					{"id": "javali_blindado", "x": 3820, "facing": -1},
					{"id": "javali_saltador", "x": 3480, "facing": -1},
				]},
			{"id": "resgate_raquel", "tipo": "resgate", "quando": "x", "x": 4080,
				"quem": "raquel", "chave": "raquel", "bonus": "cura"},
			{"id": "pre_chefe", "tipo": "dialogo", "quando": "x", "x": 4380, "chave": "chefe"},
			{"id": "arena_matriarca", "tipo": "arena", "quando": "x", "x": 4480,
				"left": 4480, "right": 5280, "chefe": "mae_javali",
				"ondas": [
					[{"id": "mae_javali", "x": 5100, "facing": -1, "boss": true}],
				]},
			{"id": "vitoria", "tipo": "dialogo", "quando": "clear", "chave": "vitoria"},
			{"id": "fim_fase", "tipo": "vitoria", "quando": "clear"},
		],
	},
	2: {
		"id": "amazonia",
		"nome": "O Inferno Verde da Amazônia",
		"estilo": "side_scroll",
		"chefe": "bufalo_rei",
		"dialogos": {
			"intro": [
				{"who": Speaker.SAMURAI, "text": "Os Búfalos da região sofreram alterações bioquímicas graves. Cuidado com as emboscadas na lama!"},
				{"who": Speaker.KIKO, "text": "Pode deixar, Samurai. Isso vai virar um safári de lama."},
			],
		},
		"eventos": [],
	},
	3: {
		"id": "jipe",
		"nome": "A Perseguição no Jipe",
		"estilo": "vehicle",
		"chefe": "dupla_titas",
		"dialogos": {
			"intro": [
				{"who": Speaker.SAMURAI, "text": "Os sobreviventes das hordas anteriores se juntaram! Segure a posição na traseira do veículo!"},
				{"who": Speaker.KIKO, "text": "Ótimo, assim não preciso caçar um por um!"},
			],
		},
		"eventos": [],
	},
	4: {
		"id": "pantanal",
		"nome": "O Desafio do Caçador",
		"estilo": "fps_gallery",
		"dialogos": {
			"intro": [
				{"who": Speaker.SAMURAI, "text": "Hora de testar sua precisão, Kiko. Não deixe a fauna local atravessar o perímetro!"},
				{"who": Speaker.KIKO, "text": "Minha mira nunca erra."},
			],
		},
		"eventos": [],
	},
	5: {
		"id": "canada",
		"nome": "Os Pinheirais Gelados do Canadá",
		"estilo": "side_scroll",
		"chefe": "alce_artico",
		"dialogos": {
			"intro": [
				{"who": Speaker.SAMURAI, "text": "O pulso afetou os animais do norte. Os Alces daqui são extremamente territoriais e fortes."},
				{"who": Speaker.KIKO, "text": "O frio congelou minha paciência. Vamos acabar com isso."},
			],
		},
		"eventos": [],
	},
	6: {
		"id": "africa",
		"nome": "O Safári da Morte na África",
		"estilo": "side_scroll",
		"chefe": "leao_rei",
		"dialogos": {
			"intro": [
				{"who": Speaker.SAMURAI, "text": "Estamos nos aproximando do complexo principal. O guardião desta região é o ápice da cadeia alimentar."},
				{"who": Speaker.KIKO, "text": "O Rei da Selva vai perder a coroa hoje."},
			],
		},
		"eventos": [],
	},
	7: {
		"id": "laboratorio",
		"nome": "O Laboratório Genético Subterrâneo",
		"estilo": "side_scroll",
		"chefe": "gorila_ciber",
		"dialogos": {
			"intro": [
				{"who": Speaker.SAMURAI, "text": "Esta é a fortaleza do Doutor Jarbas! Cuidado com os espécimes geneticamente alterados!"},
				{"who": Speaker.KIKO, "text": "A ciência foi longe demais. Hora da faxina!"},
			],
		},
		"eventos": [],
	},
	8: {
		"id": "confronto",
		"nome": "O Confronto Final",
		"estilo": "boss_arena",
		"chefe": "doutor_jarbas",
		"dialogos": {
			"intro": [
				{"who": Speaker.JARBAS, "text": "Você destruiu meus animais, mas não pode parar a Revolução! O mundo será meu!"},
				{"who": Speaker.KIKO, "text": "Chega de conversa fiada, baixinho! Seu circo acabou!"},
				{"who": Speaker.JARBAS, "text": "Companheiros, ao ataque!"},
			],
			"epilogo": [
				{"who": Speaker.NARRATOR, "text": "COM A DERROTA DO DOUTOR JARBAS, O SINAL NEURAL FOI DESTRUÍDO."},
				{"who": Speaker.NARRATOR, "text": "A FAUNA RECUPEROU SUA PAZ E O MUNDO VOLTOU AO NORMAL."},
				{"who": Speaker.NARRATOR, "text": "KIKO CUMPRIU SUA MISSÃO E RETORNOU PARA O LUGAR MAIS IMPORTANTE DE TODOS: O ABRAÇO DE SUA FAMÍLIA."},
			],
		},
		"eventos": [],
	},
}


func fase(numero: int) -> Dictionary:
	return FASES.get(numero, {})


func dialogo(numero: int, chave: String) -> Array:
	var data := fase(numero)
	if data.is_empty():
		return []
	var pack: Dictionary = data.get("dialogos", {})
	return pack.get(chave, [])


func inimigo(id: String) -> Dictionary:
	return INIMIGOS.get(id, INIMIGOS["javali_corredor"])


func speaker_name(who: int) -> String:
	return SPEAKER_NAME.get(who, "")
