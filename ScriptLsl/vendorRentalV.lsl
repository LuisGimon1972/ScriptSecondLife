// ==========================================
// VENDOR AUTOMÁTICO PRO - ITEM ÚNICO
// ✅ Com link da loja e link direto do produto
// ==========================================

// ------------------- CONFIGURAÇÃO -------------------
integer PRECIO = 250;                    // Preço em L$ (ou 0 para a versão demo)
string NOMBRE_PRODUTO = "Rental Manager"; // Nome que aparece no texto flutuante
string NOME_ARQUIVO_ITEM = "Rental Manager"; // Nome EXATO do arquivo no inventário
key DONO;                              

// 🔗 LINK DA SUA LOJA (Substitua pelo SLURL da sua loja ou perfil)
string LINK_LOJA = "https://marketplace.secondlife.com/stores/273481"; 

// 🔗 LINK DIRETO DO PRODUTO (Fornecido por você)
string LINK_PRODUTO = "https://marketplace.secondlife.com/p/Rental-Manager-v100-EN/28660265"; 

string MENSAGEM_AGRADECIMENTO = "Obrigado por comprar! 💙\nVisite minha loja: ";
// -----------------------------------------------------

integer g_contador = 0;

AtualizarTexto()
{
    llSetText(
        NOMBRE_PRODUTO + "\n" +
        "Preco: L$ " + (string)PRECIO + "\n" +
        "Vendidos: " + (string)g_contador,
        <1,1,1>, 1);
}

default
{
    state_entry()
    {
        llSetObjectName("Vendor Rental Manager v1.00"); 
        DONO = llGetOwner();
        AtualizarTexto();
        llRequestPermissions(DONO, PERMISSION_DEBIT);
        
        // Configura o preço exato para o botão de pagamento rápido
        llSetPayPrice(PAY_HIDE, [PRECIO, PAY_HIDE, PAY_HIDE, PAY_HIDE]);
    }

    touch_start(integer total)
    {
        key comprador = llDetectedKey(0);
        
        if (comprador == DONO)
        {
            llOwnerSay("✅ Vendor ativo | Produto: " + NOMBRE_PRODUTO + " | Vendidos: " + (string)g_contador);
            return;
        }

        // Se o preço for 0 (Versão Demo), entrega direto ao tocar
        if (PRECIO == 0)
        {
            if (llGetInventoryType(NOME_ARQUIVO_ITEM) == INVENTORY_NONE)
            {
                llInstantMessage(comprador, "❌ Erro: O arquivo demo não está no inventário do vendor.");
                return;
            }
            llGiveInventory(comprador, NOME_ARQUIVO_ITEM);
            llInstantMessage(comprador, "✅ Aqui está a sua versão DEMO de " + NOMBRE_PRODUTO + "!\n🔗 Página do produto: " + LINK_PRODUTO + "\n🏪 Visite nossa loja: " + LINK_LOJA);
        }
        else
        {
            llInstantMessage(comprador, "Para adquirir " + NOMBRE_PRODUTO + ", clique com o botão direito no vendor e escolha 'Pagar' (Pay) o valor de L$ " + (string)PRECIO + ".\n🔗 Veja o produto: " + LINK_PRODUTO);
        }
    }

    money(key pagador, integer valor)
    {
        // Se for um vendor pago, bloqueia pagamentos caso esteja configurado como 0
        if (PRECIO == 0)
        {
            llGiveMoney(pagador, valor);
            return;
        }

        // Valor errado → devolve o dinheiro
        if (valor != PRECIO)
        {
            llGiveMoney(pagador, valor);
            llInstantMessage(pagador, "❌ Valor incorreto!\nPreço: L$ " + (string)PRECIO + "\nDevolvido: L$ " + (string)valor);
            return;
        }

        // ✅ Valor certo → Verifica se o arquivo específico existe no inventário e o entrega
        if (llGetInventoryType(NOME_ARQUIVO_ITEM) == INVENTORY_NONE)
        {
            llGiveMoney(pagador, valor);
            llInstantMessage(pagador, "❌ Erro: O produto principal não está no inventário do vendor. Dinheiro devolvido!");
            llOwnerSay("⚠️ AVISO: O arquivo '" + NOME_ARQUIVO_ITEM + "' não foi encontrado no inventário!");
            return;
        }

        // Entrega apenas o item configurado
        llGiveInventory(pagador, NOME_ARQUIVO_ITEM);
        
        g_contador++;
        AtualizarTexto();
        
        llInstantMessage(pagador, "✅ " + MENSAGEM_AGRADECIMENTO + LINK_LOJA + "\n🔗 Detalhes do item: " + LINK_PRODUTO);
        llOwnerSay("💰 VENDA REALIZADA! → " + llKey2Name(pagador) + " levou " + NOMBRE_PRODUTO + " | Total: " + (string)g_contador);
    }
}