// DEFAULT SETTINGS (DEMO VERSION)
string status = "Disponível";
integer preco = 10; // Valor simbólico ou real para teste
integer dias = 5;

// CANAIS DE MENU E CONFIRMAÇÃO
integer canalMenu = -999;
integer canalFluxoCadastro = -555;
integer canalConfirmacaoBloqueio = -777;

// DADOS DO CLIENTE / OCUPANTE E PENDÊNCIA
key locatarioID = NULL_KEY;
string locatarioNome = "Nenhum";
integer dataVencimento = 0;

// HISTÓRICO DE INQUILINOS E VALORES
string historicoInquilinos = "Nenhum registro anterior.";
integer totalArrecadadoGeral = 0;

// Variáveis temporárias para o fluxo de cadastro
string tempOcupante = "";
integer tempValor = 0;
integer tempTempo = 0;
integer etapaCadastro = 0; 

// Variáveis de controle de pendência
string nomeTemporario = "";
key clientePagouID = NULL_KEY;
integer valorPagoPendente = 0;
integer aguardandoConfirmacao = FALSE;
integer prontoParaConfirmar = FALSE; 

// VARIÁVEL DE CONTROLE DA DEMO (Tempo em segundos - Ex: 300 segundos = 5 minutos)
integer tempoExpiracaoDemo = 300; 
integer tempoInicioDemo = 0;

// FUNÇÃO AUXILIAR: Formata o Unix Timestamp para "DD/MM/AAAA HH:MM"
string formatarDataHora(integer timestamp)
{
    integer tempoLocal = timestamp - 10800; // GMT-3 (Brasil)
    if (tempoLocal < 0) tempoLocal = 0;

    integer ano = 1970;
    integer segundosPorDia = 86400;
    integer diasTotais = tempoLocal / segundosPorDia;
    integer segundosRestantes = tempoLocal % segundosPorDia;

    integer hora = segundosRestantes / 3600;
    integer minuto = (segundosRestantes % 3600) / 60;

    integer d = diasTotais;
    
    while(TRUE)
    {
        integer diasNoAno = 365;
        if ((ano % 4 == 0 && ano % 100 != 0) || (ano % 400 == 0)) diasNoAno = 366;
        if (d >= diasNoAno)
        {
            d -= diasNoAno;
            ano++;
        }
        else jump saiAnos;
    }
    @saiAnos;

    list mesesDias = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if ((ano % 4 == 0 && ano % 100 != 0) || (ano % 400 == 0)) mesesDias = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    integer mes = 1;
    integer m = 0;
    while(m < 12)
    {
        integer diasMes = llList2Integer(mesesDias, m);
        if (d >= diasMes)
        {
            d -= diasMes;
            mes++;
        }
        else jump saiMeses;
        m++;
    }
    @saiMeses;

    integer dia = d + 1;

    string sDia = (string)dia; if (dia < 10) sDia = "0" + sDia;
    string sMes = (string)mes; if (mes < 10) sMes = "0" + sMes;
    string sHora = (string)hora; if (hora < 10) sHora = "0" + sHora;
    string sMinuto = (string)minuto; if (minuto < 10) sMinuto = "0" + sMinuto;

    return sDia + "/" + sMes + "/" + (string)ano + " " + sHora + ":" + sMinuto;
}

// FUNÇÃO: Atualiza o Texto Flutuante
atualizarTexto()
{
    if (status == "Disponível")
    {
        if (aguardandoConfirmacao)
        {
            llSetText("🟡 [DEMO] AGUARDANDO CONFIRMAÇÃO\nPagamento de: " + llKey2Name(clientePagouID) + "\n[ Versão de Teste ]", <1.0, 0.5, 0.0>, 1.0);
        }
        else if (prontoParaConfirmar)
        {
            llSetText("✅ [DEMO] CADASTRO PREPARADO\nOcupante: " + tempOcupante + "\n[ Versão de Teste ]", <1.0, 0.5, 0.0>, 1.0);
        }
        else
        {
            llSetText("⚠️ [VERSÃO DEMO] DISPONÍVEL\nExpira em 5 min após alugado!\nValor: L$ " + (string)preco, <1.0, 0.8, 0.0>, 1.0);
            llSetPayPrice(PAY_HIDE, [preco, PAY_HIDE, PAY_HIDE, PAY_HIDE]);
        }
    }
    else if (status == "Ocupada")
    {
        integer segundosPassados = llGetUnixTime() - tempoInicioDemo;
        integer segundosRestantesDemo = tempoExpiracaoDemo - segundosPassados;
        if (segundosRestantesDemo < 0) segundosRestantesDemo = 0;

        llSetText(
        "🔴 [DEMO] PROPRIEDADE EM TESTE\n"
        + "Ocupante: " + locatarioNome + "\n"
        + "⏳ Demo expira em: " + (string)(segundosRestantesDemo / 60) + "m " + (string)(segundosRestantesDemo % 60) + "s\n"
        + "[ Versão de Demonstração ]",
        <1.0, 0.0, 0.0>,
        1.0
        );
    }
    else if (status == "Bloqueada")
    {
        llSetText("🚫 [DEMO] PROPRIEDADE BLOQUEADA\n[ Versão de Teste ]", <1.0, 0.0, 0.0>, 1.0);
    }
}

// FUNÇÃO: Salva os dados na memória interna
salvarDadosInquilino()
{
    llLinksetDataWrite("status", status);
    llLinksetDataWrite("locatarioNome", locatarioNome);
    llLinksetDataWrite("locatarioID", (string)locatarioID);
    llLinksetDataWrite("dataVencimento", (string)dataVencimento);
    llLinksetDataWrite("dias", (string)dias);
    llLinksetDataWrite("preco", (string)preco);
    llLinksetDataWrite("aguardandoConfirmacao", (string)aguardandoConfirmacao);
    llLinksetDataWrite("clientePagouID", (string)clientePagouID);
    llLinksetDataWrite("valorPagoPendente", (string)valorPagoPendente);
    llLinksetDataWrite("historico", historicoInquilinos);
    llLinksetDataWrite("totalArrecadadoGeral", (string)totalArrecadadoGeral);
}

// FUNÇÃO: Carrega os dados salvos
carregarDadosInquilino()
{
    if (llLinksetDataRead("status") != "")
    {
        status = llLinksetDataRead("status");
        locatarioNome = llLinksetDataRead("locatarioNome");
        locatarioID = (key)llLinksetDataRead("locatarioID");
        dataVencimento = (integer)llLinksetDataRead("dataVencimento");
        
        if (llLinksetDataRead("dias") != "") dias = (integer)llLinksetDataRead("dias");
        if (llLinksetDataRead("preco") != "") preco = (integer)llLinksetDataRead("preco");
            
        aguardandoConfirmacao = (integer)llLinksetDataRead("aguardandoConfirmacao");
        clientePagouID = (key)llLinksetDataRead("clientePagouID");
        if (llLinksetDataRead("valorPagoPendente") != "") valorPagoPendente = (integer)llLinksetDataRead("valorPagoPendente");
        
        string h = llLinksetDataRead("historico");
        if (h != "") historicoInquilinos = h;

        if (llLinksetDataRead("totalArrecadadoGeral") != "") totalArrecadadoGeral = (integer)llLinksetDataRead("totalArrecadadoGeral");
    }
}

// FUNÇÃO: Adiciona ao histórico
adicionarAoHistorico(string nomeAntigo, integer valorPago)
{
    if (nomeAntigo != "Nenhum" && nomeAntigo != "")
    {
        totalArrecadadoGeral += valorPago;

        string registro = nomeAntigo;
        integer tamanhoNome = llStringLength(nomeAntigo);
        
        while (tamanhoNome < 15)
        {
            registro += " ";
            tamanhoNome++;
        }
        registro += "L$ " + (string)valorPago;

        if (historicoInquilinos == "Nenhum registro anterior.")
        {
            historicoInquilinos = "OCUPANTE       VALOR\n" + registro;
        }
        else
        {
            historicoInquilinos = historicoInquilinos + "\n" + registro;
        }
    }
}

default
{
    state_entry()
    {
        llSetObjectName("Rental Manager v1.00 [DEMO]");
        
        // Limpa o histórico ao iniciar o script (versão demo limpa ao resetar)
        historicoInquilinos = "Nenhum registro anterior.";
        totalArrecadadoGeral = 0;
        status = "Disponível";
        locatarioID = NULL_KEY;
        locatarioNome = "Nenhum";
        dataVencimento = 0;
        aguardandoConfirmacao = FALSE;
        prontoParaConfirmar = FALSE;
        clientePagouID = NULL_KEY;
        valorPagoPendente = 0;
        
        salvarDadosInquilino();
        carregarDadosInquilino();
        
        llListen(canalMenu, "", llGetOwner(), "");
        llListen(canalFluxoCadastro, "", llGetOwner(), "");
        llListen(canalConfirmacaoBloqueio, "", llGetOwner(), "");
        
        atualizarTexto();
    }

    touch_start(integer total_number)
    {
        key avatarID = llDetectedKey(0);

        if (avatarID == llGetOwner())
        {
            list botoes = ["Histórico", "Fechar", "Restringir", "Cadastrar", "Confirmar", "Liberar"];
            
            string mensagemPainel = "Painel DEMO (Versão de Teste)\n\n" +
                                    "👤 " + locatarioNome + "\n" +
                                    "💰 L$ " + (string)preco + "\n" +
                                    "⏱️ " + (string)dias + " dias\n" +
                                    "📊 Total Arrecadado: L$ " + (string)totalArrecadadoGeral + "\n" +
                                    "📌 Status: " + status + "\n\n" +
                                    "⚠️ Nota: Esta é a versão DEMO (expira em 5 min).";
            
            if (aguardandoConfirmacao)
            {
                mensagemPainel = "🚨 [DEMO] PAGAMENTO PENDENTE DE: " + llKey2Name(clientePagouID) + "\nClique em 'Confirmar' para aceitar.";
            }
            else if (prontoParaConfirmar)
            {
                mensagemPainel = "📝 [DEMO] CADASTRO PRONTO!\nClique em 'Confirmar' para iniciar o teste.";
            }

            llDialog(avatarID, mensagemPainel, botoes, canalMenu);
        }
        else
        {
            if (status == "Disponível")
            {
                llRegionSayTo(avatarID, 0, "[DEMO] Esta é uma versão de demonstração. Pague L$ " + (string)preco + " para testar o sistema por 5 minutos.");
            }
            else
            {
                llRegionSayTo(avatarID, 0, "[DEMO] Propriedade ocupada no momento por um testador.");
            }
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == canalMenu)
        {
            if (message == "Cadastrar" && (status == "Ocupada" || prontoParaConfirmar))
            {
                if (status == "Ocupada")
                    llOwnerSay("⚠️ Ação negada: O imóvel está ocupado na demo.");
                else
                    llOwnerSay("⚠️ Ação negada: Já existe um cadastro salvo.");
                return;
            }

            if (message == "Confirmar" && status == "Ocupada")
            {
                llOwnerSay("⚠️ Ação negada: O imóvel já está em teste.");
                return;
            }

            if (message == "Cadastrar")
            {
                etapaCadastro = 1;
                tempValor = preco; 
                tempTempo = dias;  
                llTextBox(id, "[DEMO] Passo 1/3: Digite o nome do OCUPANTE de teste:", canalFluxoCadastro);
            }
            else if (message == "Confirmar")
            {
                if (prontoParaConfirmar)
                {
                    // NÃO grava no histórico agora. O histórico só recebe após o encerramento/liberação.
                    locatarioNome = tempOcupante;
                    preco = tempValor;
                    dias = tempTempo;
                    locatarioID = NULL_KEY;

                    status = "Ocupada";
                    tempoInicioDemo = llGetUnixTime();
                    dataVencimento = tempoInicioDemo + 86400;
                    
                    prontoParaConfirmar = FALSE;
                    tempOcupante = "";

                    salvarDadosInquilino();
                    llSetTimerEvent(1.0);
                    atualizarTexto();

                    llOwnerSay("✅ [DEMO] Teste iniciado! A propriedade vai expirar automaticamente em 5 minutos.");
                }
                else if (aguardandoConfirmacao || nomeTemporario != "")
                {
                    // NÃO grava no histórico agora. O histórico só recebe após o encerramento/liberação.
                    if (nomeTemporario != "") locatarioNome = nomeTemporario;
                    else if (clientePagouID != NULL_KEY) locatarioNome = llKey2Name(clientePagouID);

                    if (clientePagouID != NULL_KEY) locatarioID = clientePagouID;

                    status = "Ocupada";
                    tempoInicioDemo = llGetUnixTime();
                    dataVencimento = tempoInicioDemo + 86400;
                    aguardandoConfirmacao = FALSE;
                    nomeTemporario = "";

                    salvarDadosInquilino();
                    llSetTimerEvent(1.0);
                    atualizarTexto();

                    llOwnerSay("✅ [DEMO] Aluguel de teste efetivado para: " + locatarioNome);
                    if (locatarioID != NULL_KEY) llRegionSayTo(locatarioID, 0, "[DEMO] Seu teste de 5 minutos começou!");
                }
                else
                {
                    llOwnerSay("⚠️ Nenhuma pendência na demo.");
                }
            }
            else if (message == "Liberar")
            {
                // Salva no histórico somente agora que está sendo liberado
                if (status == "Ocupada")
                {
                    adicionarAoHistorico(locatarioNome, preco);
                }

                status = "Disponível";
                locatarioID = NULL_KEY;
                locatarioNome = "Nenhum";
                dataVencimento = 0;
                nomeTemporario = "";
                aguardandoConfirmacao = FALSE;
                prontoParaConfirmar = FALSE;
                clientePagouID = NULL_KEY;
                valorPagoPendente = 0;
                llSetTimerEvent(0.0);
                salvarDadosInquilino();
                atualizarTexto();
                llOwnerSay("[DEMO] Imóvel liberado manualmente e histórico atualizado.");
            }
            else if (message == "Histórico")
            {
                llOwnerSay("📜 [DEMO] HISTÓRICO:\n\n" + historicoInquilinos);
            }
            else if (message == "Restringir")
            {
                llDialog(id, "⚠️ BLOQUEAR IMÓVEL NA DEMO?", ["Sim", "Não"], canalConfirmacaoBloqueio);
            }
            else if (message == "Fechar")
            {
                aguardandoConfirmacao = FALSE;
                prontoParaConfirmar = FALSE;
                clientePagouID = NULL_KEY;
                valorPagoPendente = 0;
                nomeTemporario = "";
                tempOcupante = "";
                atualizarTexto();
                llOwnerSay("❌ Operação cancelada.");
            }
        }
        else if (channel == canalConfirmacaoBloqueio)
        {
            if (message == "Sim")
            {
                if (status == "Ocupada")
                {
                    adicionarAoHistorico(locatarioNome, preco);
                }

                status = "Bloqueada";
                locatarioID = NULL_KEY;
                locatarioNome = "Bloqueado";
                salvarDadosInquilino();
                llSetTimerEvent(0.0);
                atualizarTexto();
                llOwnerSay("🔒 Imóvel bloqueado na demo.");
            }
        }
        else if (channel == canalFluxoCadastro)
        {
            if (etapaCadastro == 1)
            {
                string nomeInformado = llStringTrim(message, STRING_TRIM);
                if (nomeInformado == "") return;

                tempOcupante = llToUpper(nomeInformado);
                etapaCadastro = 2;
                llDialog(id, "[DEMO] Passo 2/3: Escolha o VALOR:", [(string)tempValor, "Outro...", "Cancelar"], canalFluxoCadastro);
            }
            else if (etapaCadastro == 2)
            {
                if (message == "Outro...") llTextBox(id, "Digite o valor:", canalFluxoCadastro);
                else if (message == "Cancelar") etapaCadastro = 0;
                else
                {
                    integer v = (integer)message;
                    if (v > 0) tempValor = v;
                    etapaCadastro = 3;
                    llDialog(id, "[DEMO] Passo 3/3: Escolha os dias:", [(string)tempTempo, "Outro...", "Cancelar"], canalFluxoCadastro);
                }
            }
            else if (etapaCadastro == 3)
            {
                if (message == "Outro...") llTextBox(id, "Digite os dias (1-365):", canalFluxoCadastro);
                else if (message == "Cancelar") etapaCadastro = 0;
                else
                {
                    integer d = (integer)message;
                    if (d >= 1 && d <= 365) 
                    {
                        tempTempo = d;
                        etapaCadastro = 0;
                        prontoParaConfirmar = TRUE; 
                        atualizarTexto();
                        llOwnerSay("📝 [DEMO] Configurado! Clique em 'Confirmar'.");
                    }
                }
            }
        }
    }

    money(key id, integer amount)
    {
        if (status == "Disponível" && amount == preco)
        {
            clientePagouID = id;
            valorPagoPendente = amount;
            aguardandoConfirmacao = TRUE; 
            
            atualizarTexto();
            llRegionSayTo(id, 0, "[DEMO] Pagamento recebido! Aguardando o dono confirmar o teste.");
            llOwnerSay("💰 [DEMO] Pagamento de " + llKey2Name(id) + ". Vá ao menu e clique em 'Confirmar'.");
        }
        else
        {
            llRegionSayTo(id, 0, "[DEMO] Valor incorreto ou ocupado. Estornando.");
            llGiveMoney(id, amount);
        }
    }

    timer()
    {
        integer agora = llGetUnixTime();
        integer tempoDecorrido = agora - tempoInicioDemo;

        atualizarTexto();

        // SE PASSAR DE 5 MINUTOS (300 segundos), EXPIRA A DEMO AUTOMATICAMENTE
        if (tempoDecorrido >= tempoExpiracaoDemo && status == "Ocupada")
        {
            llOwnerSay("🚨 [DEMO] O tempo de teste de 5 minutos expirou! Imóvel liberado automaticamente.");
            if (locatarioID != NULL_KEY) llRegionSayTo(locatarioID, 0, "[DEMO] Seu tempo de teste acabou. Obrigado por testar!");
            
            // Adiciona ao histórico exatamente no momento da expiração/liberação automática
            adicionarAoHistorico(locatarioNome, preco);
            
            status = "Disponível";
            locatarioID = NULL_KEY;
            locatarioNome = "Nenhum";
            dataVencimento = 0;
            nomeTemporario = "";
            aguardandoConfirmacao = FALSE;
            prontoParaConfirmar = FALSE;
            clientePagouID = NULL_KEY;
            valorPagoPendente = 0;
            
            salvarDadosInquilino();
            llSetTimerEvent(0.0); 
            atualizarTexto();
        }
    }
}