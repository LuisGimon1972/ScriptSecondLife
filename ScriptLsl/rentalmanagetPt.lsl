// CONFIGURAÇÕES PADRÃO
string status = "Disponível";
integer preco = 500;
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
            llSetText("🟡 AGUARDANDO CONFIRMAÇÃO\nPagamento de: " + llKey2Name(clientePagouID) + " (L$ " + (string)valorPagoPendente + ")\n[ Dono precisa confirmar no Menu ]", <1.0, 0.5, 0.0>, 1.0);
        }
        else if (prontoParaConfirmar)
        {
            llSetText("✅ CADASTRO PREPARADO\nOcupante: " + tempOcupante + " | L$ " + (string)tempValor + " (" + (string)tempTempo + " dias)\n[ Clique em 'Confirmar' no menu ]", <1.0, 0.5, 0.0>, 1.0);
        }
        else
        {
            llSetText("🟢 PROPRIEDADE DISPONÍVEL\nValor: L$ " + (string)preco + " (" + (string)dias + " dias)", <0.0, 1.0, 0.0>, 1.0);
            llSetPayPrice(PAY_HIDE, [preco, PAY_HIDE, PAY_HIDE, PAY_HIDE]);
        }
    }
    else if (status == "Ocupada")
    {
        integer tempoRestante = dataVencimento - llGetUnixTime();
        if (tempoRestante < 0) tempoRestante = 0;
        
        integer d = tempoRestante / 86400;
        integer h = (tempoRestante % 86400) / 3600;
        
        string dataVencFormatada = formatarDataHora(dataVencimento);

        llSetText(
        "🔴 PROPRIEDADE OCUPADA\n"
        + "Ocupante: " + locatarioNome + "\n"
        + "Aluguel: L$ " + (string)preco + "\n"
        + "Vencimento: " + dataVencFormatada + "\n"
        + "Tempo Restante: " + (string)d + " dias e " + (string)h + " horas",
        <1.0, 0.0, 0.0>,
        1.0
        );
    }
    else if (status == "Bloqueada")
    {
        llSetText("🚫 PROPRIEDADE BLOQUEADA\n[ Acesso restrito ]", <1.0, 0.0, 0.0>, 1.0);
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
        llSetObjectName("Rental Manager v1.00 PT");
        
        // --- LIMPEZA TOTAL PARA A VERSÃO DE VENDA ---
        // Zera o histórico e o acumulador e limpa imediatamente a LinksetData gravada no objeto
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
        
        // Sobrescreve a memória LinksetData com os dados limpos de fábrica
        salvarDadosInquilino();
        // -------------------------------------------
        
        if (status == "Ocupada") llSetTimerEvent(60.0);
        
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
            
            string mensagemPainel = "Painel de Controle do Imóvel\n\n" +
                                    "👤 " + locatarioNome + "\n" +
                                    "💰 L$ " + (string)preco + "\n" +
                                    "⏱️ " + (string)dias + " dias\n" +
                                    "📅 Vencimento: " + formatarDataHora(dataVencimento) + "\n" +
                                    "📊 Total Arrecadado: L$ " + (string)totalArrecadadoGeral + "\n" +
                                    "📌 Status: " + status;
            
            if (aguardandoConfirmacao)
            {
                mensagemPainel = "🚨 PAGAMENTO PENDENTE DE: " + llKey2Name(clientePagouID) + " (L$ " + (string)valorPagoPendente + ")\nClique em 'Confirmar' para aceitar.";
            }
            else if (prontoParaConfirmar)
            {
                mensagemPainel = "📝 CADASTRO PRONTO PARA EFETIVAR!\n- Ocupante: " + tempOcupante + "\n- Valor: L$ " + (string)tempValor + "\n- Tempo: " + (string)tempTempo + " dias\nClique em 'Confirmar' para mudar para Ocupada.";
            }

            llDialog(avatarID, mensagemPainel, botoes, canalMenu);
        }
        else
        {
            if (status == "Disponível")
            {
                if (aguardandoConfirmacao || prontoParaConfirmar)
                    llRegionSayTo(avatarID, 0, "Esta propriedade está aguardando finalização pelo proprietário.");
                else
                    llRegionSayTo(avatarID, 0, "Para alugar, clique com o botão direito na propriedade e escolha 'Pagar' (L$ " + (string)preco + ").");
            }
            else
            {
                llRegionSayTo(avatarID, 0, "Esta propriedade já está alugada.");
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
                    llOwnerSay("⚠️ Ação negada: O imóvel está ocupado. Libere-o primeiro.");
                else
                    llOwnerSay("⚠️ Ação negada: Já existe um cadastro salvo aguardando confirmação.");
                return;
            }

            if (message == "Confirmar" && status == "Ocupada")
            {
                llOwnerSay("⚠️ Ação negada: O imóvel já está ocupado.");
                return;
            }

            if (message == "Cadastrar")
            {
                etapaCadastro = 1;
                tempValor = preco; 
                tempTempo = dias;  
                llTextBox(id, "Passo 1/3: Digite o nome do OCUPANTE:", canalFluxoCadastro);
            }
            else if (message == "Confirmar")
            {
                if (prontoParaConfirmar)
                {
                    if (locatarioNome != "Nenhum" && locatarioNome != "") 
                        adicionarAoHistorico(locatarioNome, preco);

                    locatarioNome = tempOcupante;
                    preco = tempValor;
                    dias = tempTempo;
                    locatarioID = NULL_KEY;

                    status = "Ocupada";
                    dataVencimento = llGetUnixTime() + (dias * 86400);
                    
                    prontoParaConfirmar = FALSE;
                    tempOcupante = "";

                    salvarDadosInquilino();
                    llSetTimerEvent(60.0);
                    atualizarTexto();

                    llOwnerSay("✅ Status alterado para OCUPADA! Ocupante: " + locatarioNome + " (L$ " + (string)preco + ")");
                }
                else if (aguardandoConfirmacao || nomeTemporario != "")
                {
                    if (locatarioNome != "Nenhum" && locatarioNome != "") 
                        adicionarAoHistorico(locatarioNome, preco);

                    if (nomeTemporario != "") locatarioNome = nomeTemporario;
                    else if (clientePagouID != NULL_KEY) locatarioNome = llKey2Name(clientePagouID);

                    if (clientePagouID != NULL_KEY) locatarioID = clientePagouID;

                    if (valorPagoPendente > 0) preco = valorPagoPendente;

                    status = "Ocupada";
                    dataVencimento = llGetUnixTime() + (dias * 86400);
                    aguardandoConfirmacao = FALSE;
                    nomeTemporario = "";

                    salvarDadosInquilino();
                    llSetTimerEvent(60.0);
                    atualizarTexto();

                    llOwnerSay("✅ Aluguel efetivado para: " + locatarioNome + " (L$ " + (string)preco + ")");
                    if (locatarioID != NULL_KEY) llRegionSayTo(locatarioID, 0, "Sua locação foi confirmada pelo proprietário!");
                }
                else
                {
                    llOwnerSay("⚠️ Nenhuma pendência ou cadastro aguardando confirmação.");
                }
            }
            else if (message == "Liberar")
            {
                if (locatarioNome != "Nenhum" && status != "Bloqueada") 
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
                llSetTimerEvent(0.0);
                salvarDadosInquilino();
                atualizarTexto();
                llOwnerSay("Imóvel liberado e salvo no histórico. Status: Disponível.");
            }
            else if (message == "Histórico")
            {
                llOwnerSay("📜 HISTÓRICO DE OCUPANTES:\n\n" + historicoInquilinos + "\n----------------------------------\nTOTAL         L$ " + (string)totalArrecadadoGeral);
            }
            else if (message == "Restringir")
            {
                llDialog(id, "⚠️ TEM CERTEZA QUE DESEJA RESTRIGIR/BLOQUEAR O IMÓVEL?\nIsso vai encerrar a locação atual (se houver).", ["Sim", "Não"], canalConfirmacaoBloqueio);
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
                llOwnerSay("❌ Operação pendente descartada.");
            }
        }
        else if (channel == canalConfirmacaoBloqueio)
        {
            if (message == "Sim")
            {
                if (locatarioNome != "Nenhum" && status == "Ocupada") 
                    adicionarAoHistorico(locatarioNome, preco);

                status = "Bloqueada";
                locatarioID = NULL_KEY;
                locatarioNome = "Bloqueado";
                dataVencimento = 0;
                salvarDadosInquilino();
                llSetTimerEvent(0.0);
                atualizarTexto();
                llOwnerSay("🔒 Imóvel restrito/bloqueado com sucesso.");
            }
            else
            {
                llOwnerSay("❌ Operação de restrição cancelada.");
            }
        }
        else if (channel == canalFluxoCadastro)
        {
            if (etapaCadastro == 1)
            {
                string nomeInformado = llStringTrim(message, STRING_TRIM);
                
                if (nomeInformado == "")
                {
                    llTextBox(id, "⚠️ Nome inválido!\nDigite o nome do OCUPANTE:", canalFluxoCadastro);
                    return;
                }

                tempOcupante = llToUpper(nomeInformado);
                etapaCadastro = 2;
                
                llDialog(id, "Passo 2/3: Escolha o VALOR em L$\n(Valor Atual: L$ " + (string)tempValor + ")", [(string)tempValor, "Outro...", "Cancelar"], canalFluxoCadastro);
            }
            else if (etapaCadastro == 2)
            {
                if (message == "Outro...")
                {
                    llTextBox(id, "Digite o novo VALOR em L$:", canalFluxoCadastro);
                }
                else if (message == "Cancelar")
                {
                    etapaCadastro = 0;
                    llOwnerSay("❌ Cadastro cancelado.");
                }
                else
                {
                    integer valorInformado = (integer)message;
                    if (valorInformado > 0) tempValor = valorInformado;

                    etapaCadastro = 3;
                    llDialog(id, "Passo 3/3: Escolha o TEMPO em dias\n(Tempo Atual: " + (string)tempTempo + " dias)", [(string)tempTempo, "Outro...", "Cancelar"], canalFluxoCadastro);
                }
            }
            else if (etapaCadastro == 3)
            {
                if (message == "Outro...")
                {
                    llTextBox(id, "Digite o novo TEMPO em dias (1 a 365):", canalFluxoCadastro);
                }
                else if (message == "Cancelar")
                {
                    etapaCadastro = 0;
                    llOwnerSay("❌ Cadastro cancelado.");
                }
                else
                {
                    integer diasInformados = (integer)message;
                    
                    if (diasInformados >= 1 && diasInformados <= 365) 
                    {
                        tempTempo = diasInformados;
                        etapaCadastro = 0;
                        prontoParaConfirmar = TRUE; 

                        atualizarTexto();
                        llOwnerSay("📝 Dados configurados!\n- Ocupante: " + tempOcupante + "\n- Valor: L$ " + (string)tempValor + "\n- Tempo: " + (string)tempTempo + " dias\n👉 Clique em 'Confirmar' no menu principal para efetivar.");
                    }
                    else
                    {
                        llTextBox(id, "⚠️ VALOR INVÁLIDO!\nPor favor, digite um tempo entre 1 e 365 dias:", canalFluxoCadastro);
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
            llRegionSayTo(id, 0, "Pagamento recebido! Aguardando confirmação do proprietário.");
            llOwnerSay("💰 PAGAMENTO DE " + llKey2Name(id) + " (L$ " + (string)amount + "). Vá ao menu e clique em 'Confirmar'.");
        }
        else if (status == "Ocupada" && id == locatarioID && amount == preco)
        {
            dataVencimento = dataVencimento + (dias * 86400);
            totalArrecadadoGeral += amount; 
            salvarDadosInquilino();
            atualizarTexto();
            
            llRegionSayTo(id, 0, "Renovação aceita! Mais " + (string)dias + " dias adicionados.");
            llOwnerSay("🔄 Aluguel renovado por " + locatarioNome + " (+ L$ " + (string)amount + ")");
        }
        else
        {
            llRegionSayTo(id, 0, "Valor incorreto ou imóvel ocupado. Estornando pagamento.");
            llGiveMoney(id, amount);
        }
    }

    timer()
    {
        integer agora = llGetUnixTime();
        atualizarTexto();

        if (agora >= dataVencimento && status == "Ocupada")
        {
            llOwnerSay("🚨 O aluguel de " + locatarioNome + " venceu!");
            llRegionSayTo(locatarioID, 0, "Seu prazo de locação terminou.");
            
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