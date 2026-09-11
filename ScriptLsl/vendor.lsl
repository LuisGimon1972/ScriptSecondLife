// ==========================================
// VENDOR AUTOMÁTICO PRO - LICENÇA DE SCRIPT
// ✅ Avisos de status e segurança restritos apenas ao dono
// ==========================================

// ------------------- CONFIGURAÇÃO -------------------
integer PRECIO = 300;                        // Preço da licença em L$
string NOMBRE_PRODUTO = "Vendor Automático Pro"; // Nome exibido no texto flutuante
string NOME_ARQUIVO_ITEM = "Script Vendor Pro";  // Nome EXATO do item no inventário
key DONO;                              

// 🔗 LINKS DE DIVULGAÇÃO
string LINK_LOJA = "secondlife:///app/agent/YOUR_UUID_HERE/about"; 
string LINK_PRODUTO = "url:https://marketplace.secondlife.com/p/Personal-Planner-DEMO/28661509 [Ver Página do Produto]"; 

string MENSAGEM_AGRADECIMENTO = "Obrigado por adquirir a licença do script! 💙\nVisite minha loja: ";
// -----------------------------------------------------

integer g_contador = 0;

AtualizarTexto()
{
    llSetText(
        NOMBRE_PRODUTO + "\n" +
        "Licença: L$ " + (string)PRECIO + "\n" +
        "Vendidos: " + (string)g_contador,
        <1,1,1>, 1);
}

default
{
    state_entry()
    {
        DONO = llGetOwner();
        AtualizarTexto();
        llRequestPermissions(DONO, PERMISSION_DEBIT);
        llSetPayPrice(PAY_HIDE, [PRECIO, PAY_HIDE, PAY_HIDE, PAY_HIDE]);
        
        // 🔒 Aviso de segurança e status exibido EXCLUSIVAMENTE ao dono
        llOwnerSay("✅ Vendor inicializado com sucesso!\n- Produto: " + NOMBRE_PRODUTO + "\n- Preço: L$ " + (string)PRECIO + "\n- Permissão de débito pronta.");
    }

    touch_start(integer total)
    {
        key comprador = llDetectedKey(0);
        
        // Se quem clicou for o dono, exibe o painel de controle privado
        if (comprador == DONO)
        {
            llOwnerSay("⚙️ Menu do Dono | Total de licenças vendidas: " + (string)g_contador);
            return;
        }

        // Para os clientes, exibe de forma limpa apenas as instruções de compra
        llInstantMessage(comprador, "Para adquirir a licença de " + NOMBRE_PRODUTO + ", clique com o botão direito no vendor e escolha 'Pagar' (Pay) o valor de L$ " + (string)PRECIO + ".\n🔗 " + LINK_PRODUTO);
    }

    money(key pagador, integer valor)
    {
        if (valor != PRECIO)
        {
            llGiveMoney(pagador, valor);
            llInstantMessage(pagador, "❌ Valor incorreto!\nPreço da licença: L$ " + (string)PRECIO + "\nDevolvido: L$ " + (string)valor);
            return;
        }

        if (llGetInventoryType(NOME_ARQUIVO_ITEM) == INVENTORY_NONE)
        {
            llGiveMoney(pagador, valor);
            llInstantMessage(pagador, "❌ Erro: O arquivo do script não está no inventário do vendor. Dinheiro devolvido!");
            llOwnerSay("⚠️ AVISO: O script '" + NOME_ARQUIVO_ITEM + "' não foi encontrado no inventário!");
            return;
        }

        // Entrega o script ao comprador
        llGiveInventory(pagador, NOME_ARQUIVO_ITEM);
        
        g_contador++;
        AtualizarTexto();
        
        llInstantMessage(pagador, "✅ " + MENSAGEM_AGRADECIMENTO + LINK_LOJA);
        llOwnerSay("💰 LICENÇA VENDIDA! → " + llKey2Name(pagador) + " comprou o " + NOMBRE_PRODUTO + " | Total: " + (string)g_contador);
    }
}