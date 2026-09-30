import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function buildPrompt(
  type: string,
  themeName: string,
  category?: string,
  level?: number
): string {
  if (type === "reading") {
    const categoryLabels: Record<string, string> = {
      textos: "Textos Espirituais",
      parabolas: "Parábolas",
      salmos: "Salmos",
      versiculos: "Versículos Bíblicos",
      sabedorias: "Sabedorias",
    };
    const catLabel = categoryLabels[category ?? "textos"] ?? category;
    return `Você é um escritor espiritual experiente. Gere uma leitura espiritual do tipo "${catLabel}" sobre o tema "${themeName}", para o nível ${level ?? 1} de 7 (onde 1 é iniciante e 7 é avançado na jornada de fé).

A leitura deve ser inspiradora, profunda e adequada ao nível espiritual indicado. Níveis mais baixos devem ter linguagem mais acessível; níveis mais altos podem ser mais contemplativos e profundos.

Retorne APENAS um JSON válido com esta estrutura:
{"title": "título da leitura", "content": "texto completo da leitura com 3 a 5 parágrafos"}`;
  }

  if (type === "prayer") {
    return `Você é um líder espiritual experiente. Gere uma oração original e inspiradora sobre o tema "${themeName}".

A oração deve ser sincera, tocante e adequada para momentos de reflexão pessoal. Deve ter entre 2 a 4 parágrafos.

Retorne APENAS um JSON válido com esta estrutura:
{"title": "título da oração", "content": "texto completo da oração"}`;
  }

  if (type === "quiz") {
    return `Você é um educador religioso experiente. Gere um quiz sobre o tema "${themeName}" com exatamente 5 perguntas de múltipla escolha.

Cada pergunta deve ter 4 alternativas (a, b, c, d) com apenas uma correta. As perguntas devem testar conhecimento espiritual e bíblico de forma educativa e interessante.

Retorne APENAS um JSON válido com esta estrutura:
{"title": "título do quiz", "questions": [{"question_text": "pergunta", "option_a": "alternativa a", "option_b": "alternativa b", "option_c": "alternativa c", "option_d": "alternativa d", "correct_option": "a"}]}

Importante: correct_option deve ser apenas a letra (a, b, c ou d).`;
  }

  throw new Error(`Tipo desconhecido: ${type}`);
}

function buildFallbackContent(type: string, themeName: string): Record<string, unknown> {
  if (type === "quiz") {
    return {
      title: `Quiz: ${themeName}`,
      questions: [
        { question_text: `Qual é o principal ensinamento sobre ${themeName} na Bíblia?`, option_a: "Amor ao próximo", option_b: "Prosperidade material", option_c: "Isolamento espiritual", option_d: "Indiferença", correct_option: "a" },
        { question_text: `Como podemos praticar ${themeName} no dia a dia?`, option_a: "Ignorando os outros", option_b: "Com ações de bondade e compaixão", option_c: "Apenas em orações", option_d: "Somente aos domingos", correct_option: "b" },
        { question_text: `Qual livro da Bíblia mais fala sobre ${themeName}?`, option_a: "Apocalipse", option_b: "Levítico", option_c: "Salmos", option_d: "Números", correct_option: "c" },
        { question_text: `O que Jesus ensinou sobre ${themeName}?`, option_a: "Que não é importante", option_b: "Que devemos praticá-lo sempre", option_c: "Que é opcional", option_d: "Que é apenas para líderes", correct_option: "b" },
        { question_text: `Como ${themeName} transforma nossa vida espiritual?`, option_a: "Nos afasta de Deus", option_b: "Não tem efeito", option_c: "Nos aproxima de Deus e do próximo", option_d: "Apenas nos traz benefícios materiais", correct_option: "c" },
      ],
    };
  }
  return {
    title: type === "prayer" ? `Oração: ${themeName}` : `Reflexão: ${themeName}`,
    content: type === "prayer"
      ? `Senhor, neste momento de oração sobre ${themeName}, abro meu coração para a Tua presença. Ajuda-me a compreender os Teus caminhos e a viver segundo a Tua vontade.\n\nQue a Tua luz ilumine minha jornada e que eu encontre paz e sabedoria em cada passo. Que ${themeName} se torne uma fonte de transformação em minha vida.\n\nEm Teu nome, amém.`
      : `${themeName} é um dos pilares fundamentais da vida espiritual. Ao longo dos séculos, grandes mestres e escrituras sagradas nos ensinaram sobre a importância de cultivar essa virtude em nosso coração.\n\nQuando nos dedicamos a compreender ${themeName}, descobrimos que não se trata apenas de um conceito, mas de uma prática viva que transforma nosso ser interior. É através dessa busca sincera que encontramos conexão com o divino.\n\nQue possamos, a cada dia, aprofundar nossa compreensão e vivência de ${themeName}, permitindo que essa sabedoria guie nossos passos e ilumine nosso caminho.`,
  };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { type, theme_name, category, level } = await req.json();

    if (!type || !theme_name) {
      return new Response(
        JSON.stringify({ error: "type e theme_name são obrigatórios" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiApiKey) {
      return new Response(
        JSON.stringify({ error: "GEMINI_API_KEY não configurada" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const prompt = buildPrompt(type, theme_name, category, level);

    const models = ["gemini-3.6-flash", "gemini-2.0-flash"];
    const requestBody = JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.9,
      },
    });

    let parsed: Record<string, unknown> | null = null;

    for (const model of models) {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiApiKey}`;
      for (let attempt = 0; attempt < 3; attempt++) {
        try {
          const res = await fetch(url, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: requestBody,
          });
          if (res.ok) {
            const data = await res.json();
            const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
            parsed = JSON.parse(text);
            break;
          }
          if (res.status !== 503 && res.status !== 429) break;
          await new Promise((r) => setTimeout(r, 1000 * Math.pow(2, attempt)));
        } catch { /* retry */ }
      }
      if (parsed) break;
    }

    if (!parsed) {
      parsed = buildFallbackContent(type, theme_name);
    }

    return new Response(JSON.stringify(parsed), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: `Erro interno: ${(err as Error).message}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
