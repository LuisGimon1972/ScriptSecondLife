// ==========================================
// VENDOR AUTOMÁTICO PRO - MULTI-PRODUTO
// 📦 Produtos: Rental Manager & Personal Planner
// ==========================================

integer PRECIO = 500;                  
string NOMBRE_PRODUTO = "Rental Manager & Personal Planner"; 
key DONO;                              
string LINK_LOJA = "secondlife:///app/agent/YOUR_UUID_HERE/about"; 
string MENSAGEM_AGRADECIMENTO = "Obrigado por comprar! 💙\nVisite minha loja: ";

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
        DONO = llGetOwner();
        AtualizarTexto();
        llRequestPermissions(DONO, PERMISSION_DEBIT);
        
        // Configura o objeto para receber o valor exato no clique de pagamento
        llSetPayPrice(PAY_HIDE, [PRECIO, PAY_HIDE, PAY_HIDE, PAY_HIDE]);
    }

    touch_start(integer total)
    {
        key comprador = llDetectedKey(0);
        
        if (comprador == DONO)
        {
            llOwnerSay("✅ Vendor ativo | Vendidos: " + (string)g_contador + " | Preço: L$ " + (string)PRECIO);
            return;
        }

        // Instrução enviada ao cliente quando ele toca no vendor
        llInstantMessage(comprador, "Para adquirir o " + NOMBRE_PRODUTO + ", clique com o botão direito no vendor e escolha 'Pagar' (Pay) o valor de L$ " + (string)PRECIO + ".");
    }

    money(key pagador, integer valor)
    {
        // Valor errado → devolve o dinheiro
        if (valor != PRECIO)
        {
            llGiveMoney(pagador, valor);
            llInstantMessage(pagador, "❌ Valor incorreto!\nPreço: L$ " + (string)PRECIO + "\nDevolvido: L$ " + (string)valor);
            return;
        }

        // ✅ Valor certo → entrega todos os itens do inventário de uma vez (Rental Manager + Personal Planner)
        integer total_itens = llGetInventoryNumber(INVENTORY_ALL);
        integer entregou = FALSE;
        integer i;

        for (i = 0; i < total_itens; i++)
        {
            string item = llGetInventoryName(INVENTORY_ALL, i);
            
            // Entrega tudo o que estiver no inventário, exceto o próprio script do vendor
            if (item != llGetScriptName())
            {
                llGiveInventory(pagador, item);
                entregou = TRUE;
            }
        }

        if (entregou)
        {
            g_contador++;
            AtualizarTexto();
            
            llInstantMessage(pagador, "✅ " + MENSAGEM_AGRADECIMENTO + LINK_LOJA);
            llOwnerSay("💰 VENDA REALIZADA! → " + llKey2Name(pagador) + " | Total de vendas: " + (string)g_contador);
        }
        else
        {
            llGiveMoney(pagador, valor);
            llInstantMessage(pagador, "❌ Nenhum item encontrado no inventário do vendor. Dinheiro devolvido!");
            llOwnerSay("⚠️ AVISO: O vendor foi acionado, mas está sem produtos no inventário!");
        }
    }
}