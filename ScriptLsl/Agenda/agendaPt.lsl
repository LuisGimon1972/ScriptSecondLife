// AGENDA PESSOAL E DE EVENTOS - SECOND LIFE (LSL) v4.07
// Com Confirmação de Segurança (Validação) para "Zerar Tudo"

string versao = "Personal Planner v1.00 PT";

integer canalMenu = -8811;
integer canalFluxo = -8822;

integer etapa = 0; 
string tempTitulo = "";
string tempTipo = "Evento";
string tempDia = "";
string tempHora = "";
integer tempAntecedencia = 15;
integer idAlvoEdicao = 0;

string historicoCompromissos = "Nenhum histórico registrado.";

string formatarDataHora(integer timestamp)
{
    integer tempoLocal = timestamp - 10800; 
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
        if (d >= diasNoAno) { d -= diasNoAno; ano++; }
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
        if (d >= diasMes) { d -= diasMes; mes++; }
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

integer checarValidadeTimestamp(string dataStr, string horaStr)
{
    list partesData = llParseString2List(dataStr, ["/"], []);
    list partesHora = llParseString2List(horaStr, [":"], []);
    
    if (llGetListLength(partesData) != 3 || llGetListLength(partesHora) != 2) return 0;
    
    integer dia = (integer)llList2String(partesData, 0);
    integer mes = (integer)llList2String(partesData, 1);
    integer ano = (integer)llList2String(partesData, 2);
    integer hora = (integer)llList2String(partesHora, 0);
    integer min = (integer)llList2String(partesHora, 1);

    if (ano < 2024 || mes < 1 || mes > 12 || dia < 1 || dia > 31) return 0;
    if (hora < 0 || hora > 23 || min < 0 || min > 59) return 0;

    integer d = 0;
    integer y = 1970;
    while (y < ano)
    {
        integer bissexto = 0;
        if ((y % 4 == 0 && y % 100 != 0) || (y % 400 == 0)) bissexto = 1;
        d += 365 + bissexto;
        y++;
    }

    list mesesDias = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if ((ano % 4 == 0 && ano % 100 != 0) || (ano % 400 == 0)) mesesDias = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    if (dia > llList2Integer(mesesDias, mes - 1)) return 0;

    integer i = 0;
    while (i < mes - 1)
    {
        d += llList2Integer(mesesDias, i);
        i++;
    }

    d += (dia - 1);
    integer timestamp = (d * 86400) + (hora * 3600) + (min * 60) + 10800; 

    if (timestamp <= llGetUnixTime()) return -1;

    return timestamp;
}

adicionarAoHistorico(string titulo, string tipo, string acao, integer timestamp)
{
    string registro = acao + ": " + titulo + " (" + tipo + ") - Ref: " + formatarDataHora(timestamp);
    
    if (historicoCompromissos == "Nenhum histórico registrado.")
    {
        historicoCompromissos = registro;
    }
    else
    {
        historicoCompromissos = historicoCompromissos + "\n" + registro;
    }
    llLinksetDataWrite("historico", historicoCompromissos);
}

carregarEstado()
{
    string h = llLinksetDataRead("historico");
    if (h != "") historicoCompromissos = h;
}

atualizarTextoFlutuante()
{
    integer total = (integer)llLinksetDataRead("total_eventos");
    if (total <= 0)
    {
        llSetText("📅 AGENDA PESSOAL\nNenhum compromisso cadastrado.", <0.0, 1.0, 0.0>, 1.0);
        return;
    }

    integer agora = llGetUnixTime();
    integer menorTempo = 2147483647;
    string proximoNome = "Nenhum";

    integer i = 1;
    while (i <= total)
    {
        string dados = llLinksetDataRead("evento_" + (string)i);
        if (dados != "")
        {
            list partes = llParseString2List(dados, ["|"], []);
            string titulo = llList2String(partes, 0);
            string tipo = llList2String(partes, 1);
            integer timestamp = (integer)llList2String(partes, 2);

            if (tipo == "Aniversario" && timestamp < agora)
            {
                timestamp += 31536000; 
            }

            if (timestamp > agora && timestamp < menorTempo)
            {
                menorTempo = timestamp;
                proximoNome = titulo;
            }
        }
        i++;
    }

    if (menorTempo == 2147483647)
    {
        llSetText("📅 AGENDA PESSOAL\nNenhum evento futuro próximo.", <1.0, 1.0, 0.0>, 1.0);
    }
    else
    {
        string dataFmt = formatarDataHora(menorTempo);
        llSetText("📅 PRÓXIMO COMPROMISSO:\n" + proximoNome + "\n🕒 " + dataFmt, <0.0, 0.8, 1.0>, 1.0);
    }
}

default
{
    state_entry()
    {
        llSetObjectName("Personal Planner v1.00 PT");
        carregarEstado();
        llSetTimerEvent(60.0);
        
        llListen(canalMenu, "", llGetOwner(), "");
        llListen(canalFluxo, "", llGetOwner(), "");
        
        atualizarTextoFlutuante();
    }

    touch_start(integer total_number)
    {
        if (llDetectedKey(0) == llGetOwner())
        {
            list botoes = ["Excluir", "Historico", "Zerar Tudo", "Ver Lista", "Adicionar", "Editar"];
            llDialog(llGetOwner(), "Painel da Agenda Pessoal\nEscolha uma opção:", botoes, canalMenu);
        }
        else
        {
            llRegionSayTo(llDetectedKey(0), 0, "Esta é uma agenda pessoal restrita ao proprietário.");
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == canalMenu)
        {
            if (message == "Adicionar")
            {
                etapa = 1;
                tempTitulo = "";
                llTextBox(id, "Passo 1/5: Digite o TÍTULO do compromisso:", canalFluxo);
            }
            else if (message == "Ver Lista")
            {
                integer total = (integer)llLinksetDataRead("total_eventos");
                if (total <= 0)
                {
                    llOwnerSay("📂 Sua agenda está vazia.");
                    return;
                }

                string listaCompleta = "📂 SEUS COMPROMISSOS CADASTRADOS:\n\n";
                integer i = 1;
                while (i <= total)
                {
                    string dados = llLinksetDataRead("evento_" + (string)i);
                    if (dados != "")
                    {
                        list partes = llParseString2List(dados, ["|"], []);
                        string titulo = llList2String(partes, 0);
                        string tipo = llList2String(partes, 1);
                        integer timestamp = (integer)llList2String(partes, 2);
                        integer antecedencia = (integer)llList2String(partes, 3);
                        
                        listaCompleta += "[" + (string)i + "] " + titulo + " (" + tipo + ") - " + formatarDataHora(timestamp) + " [Alerta: " + (string)antecedencia + "m]\n";
                    }
                    i++;
                }
                llOwnerSay(listaCompleta);
            }
            else if (message == "Editar")
            {
                integer total = (integer)llLinksetDataRead("total_eventos");
                if (total <= 0)
                {
                    llOwnerSay("⚠️ Não há eventos para editar.");
                    return;
                }
                etapa = 7;
                llTextBox(id, "Digite o NÚMERO do evento que deseja EDITAR:", canalFluxo);
            }
            else if (message == "Excluir")
            {
                integer total = (integer)llLinksetDataRead("total_eventos");
                if (total <= 0)
                {
                    llOwnerSay("⚠️ Não há eventos para excluir.");
                    return;
                }
                etapa = 6;
                llTextBox(id, "Digite o NÚMERO do compromisso que deseja cancelar/apagar:", canalFluxo);
            }
            else if (message == "Historico")
            {
                llOwnerSay("📜 HISTÓRICO DE COMPROMISSOS:\n\n" + historicoCompromissos);
            }
            else if (message == "Zerar Tudo")
            {
                etapa = 12;
                llTextBox(id, "⚠️ ATENÇÃO: Você solicitou apagar TUDO!\n\nIsso vai remover permanentemente todos os seus compromissos cadastrados e o histórico de eventos.\n\nPara confirmar, digite exatamente: SIM", canalFluxo);
            }
        }
        else if (channel == canalFluxo)
        {
            // CADASTRO - 1: Título
            if (etapa == 1)
            {
                tempTitulo = llStringTrim(message, STRING_TRIM);
                if (tempTitulo == "")
                {
                    llTextBox(id, "⚠️ Título inválido. Digite novamente:", canalFluxo);
                    return;
                }
                etapa = 2;
                llDialog(id, "Passo 2/5: Escolha o tipo de compromisso:", ["Evento", "Aniversario"], canalFluxo);
            }
            // CADASTRO - 2: Tipo
            else if (etapa == 2)
            {
                tempTipo = message;
                etapa = 3;
                llTextBox(id, "Passo 3/5: Digite a DATA no formato DD/MM/AAAA\n(Ex: 25/12/2026):", canalFluxo);
            }
            // CADASTRO - 3: Data
            else if (etapa == 3)
            {
                tempDia = llStringTrim(message, STRING_TRIM);
                list pData = llParseString2List(tempDia, ["/"], []);
                if (llGetListLength(pData) != 3)
                {
                    llOwnerSay("❌ ERRO: Formato de data incorreto! Use DD/MM/AAAA.");
                    llTextBox(id, "Passo 3/5: Digite a DATA novamente no formato DD/MM/AAAA:", canalFluxo);
                    return;
                }

                integer diaVal = (integer)llList2String(pData, 0);
                integer mesVal = (integer)llList2String(pData, 1);
                integer anoVal = (integer)llList2String(pData, 2);

                if (anoVal < 2024 || mesVal < 1 || mesVal > 12 || diaVal < 1 || diaVal > 31)
                {
                    llOwnerSay("❌ ERRO: Data inválida (dia, mês ou ano fora dos limites).");
                    llTextBox(id, "Passo 3/5: Digite uma DATA válida (DD/MM/AAAA):", canalFluxo);
                    return;
                }

                etapa = 4;
                llTextBox(id, "Passo 4/5: Digite o HORÁRIO no formato HH:MM\n(Ex: 14:30):", canalFluxo);
            }
            // CADASTRO - 4: Hora
            else if (etapa == 4)
            {
                tempHora = llStringTrim(message, STRING_TRIM);
                list pHora = llParseString2List(tempHora, [":"], []);
                if (llGetListLength(pHora) != 2)
                {
                    llOwnerSay("❌ ERRO: Formato de horário incorreto! Use HH:MM.");
                    llTextBox(id, "Passo 4/5: Digite o HORÁRIO novamente no formato HH:MM:", canalFluxo);
                    return;
                }

                integer horaVal = (integer)llList2String(pHora, 0);
                integer minVal = (integer)llList2String(pHora, 1);
                if (horaVal < 0 || horaVal > 23 || minVal < 0 || minVal > 59)
                {
                    llOwnerSay("❌ ERRO: Horário inválido (horas de 00-23 e minutos de 00-59).");
                    llTextBox(id, "Passo 4/5: Digite um HORÁRIO válido (HH:MM):", canalFluxo);
                    return;
                }

                integer testeTemp = checarValidadeTimestamp(tempDia, tempHora);
                if (testeTemp == -1)
                {
                    llOwnerSay("❌ ERRO NO ENVIO: A data/horário (" + tempDia + " às " + tempHora + ") já passou!");
                    llTextBox(id, "Passo 4/5: Digite um HORÁRIO futuro válido (HH:MM):", canalFluxo);
                    return;
                }
                else if (testeTemp == 0)
                {
                    llOwnerSay("❌ ERRO NO ENVIO: Data ou horário inválidos.");
                    llTextBox(id, "Passo 4/5: Digite um HORÁRIO válido (HH:MM):", canalFluxo);
                    return;
                }

                etapa = 5;
                llDialog(id, "Passo 5/5: Minutos de antecedência para o alerta:", ["0", "15", "30", "60"], canalFluxo);
            }
            // CADASTRO - 5: Antecedência e Gravação Final
            else if (etapa == 5)
            {
                tempAntecedencia = (integer)message;
                integer timestampFinal = checarValidadeTimestamp(tempDia, tempHora);

                if (timestampFinal <= 0)
                {
                    llOwnerSay("❌ Erro temporal no cadastro. Reinicie o processo.");
                    etapa = 0;
                    return;
                }

                integer total = (integer)llLinksetDataRead("total_eventos");
                total++;
                
                string registro = tempTitulo + "|" + tempTipo + "|" + (string)timestampFinal + "|" + (string)tempAntecedencia;
                llLinksetDataWrite("evento_" + (string)total, registro);
                llLinksetDataWrite("total_eventos", (string)total);

                etapa = 0;
                atualizarTextoFlutuante();
                llOwnerSay("✅ Compromisso cadastrado com sucesso!");
            }
            
            // EXCLUSÃO MANUAL
            else if (etapa == 6)
            {
                integer idExcluir = (integer)message;
                integer total = (integer)llLinksetDataRead("total_eventos");

                if (idExcluir > 0 && idExcluir <= total)
                {
                    string dadosExcluidos = llLinksetDataRead("evento_" + (string)idExcluir);
                    list partes = llParseString2List(dadosExcluidos, ["|"], []);
                    string titulo = llList2String(partes, 0);
                    string tipo = llList2String(partes, 1);
                    integer timestamp = (integer)llList2String(partes, 2);

                    adicionarAoHistorico(titulo, tipo, "❌ Cancelado/Removido", timestamp);

                    llLinksetDataDelete("evento_" + (string)idExcluir);
                    llOwnerSay("🗑️ Evento #" + (string)idExcluir + " (" + titulo + ") cancelado e enviado para o histórico.");
                    atualizarTextoFlutuante();
                }
                else
                {
                    llOwnerSay("⚠️ Número inválido.");
                }
                etapa = 0;
            }

            // EDIÇÃO - 1: Selecionar ID
            else if (etapa == 7)
            {
                idAlvoEdicao = (integer)message;
                integer total = (integer)llLinksetDataRead("total_eventos");

                if (idAlvoEdicao > 0 && idAlvoEdicao <= total)
                {
                    string dadosAtuais = llLinksetDataRead("evento_" + (string)idAlvoEdicao);
                    list partes = llParseString2List(dadosAtuais, ["|"], []);
                    tempTitulo = llList2String(partes, 0);
                    tempTipo = llList2String(partes, 1);

                    etapa = 8;
                    llTextBox(id, "Editando Evento #" + (string)idAlvoEdicao + "\nDigite o NOVO TÍTULO (Atual: " + tempTitulo + "):", canalFluxo);
                }
                else
                {
                    llOwnerSay("⚠️ Número inválido para edição.");
                    etapa = 0;
                }
            }
            // EDIÇÃO - 2: Novo Título
            else if (etapa == 8)
            {
                string novoTitulo = llStringTrim(message, STRING_TRIM);
                if (novoTitulo != "") tempTitulo = novoTitulo;

                etapa = 9;
                llTextBox(id, "Digite a NOVA DATA no formato DD/MM/AAAA:", canalFluxo);
            }
            // EDIÇÃO - 3: Nova Data
            else if (etapa == 9)
            {
                tempDia = llStringTrim(message, STRING_TRIM);
                list pData = llParseString2List(tempDia, ["/"], []);
                if (llGetListLength(pData) != 3)
                {
                    llOwnerSay("❌ ERRO: Formato de data incorreto! Use DD/MM/AAAA.");
                    llTextBox(id, "Digite a NOVA DATA novamente (DD/MM/AAAA):", canalFluxo);
                    return;
                }

                integer diaVal = (integer)llList2String(pData, 0);
                integer mesVal = (integer)llList2String(pData, 1);
                integer anoVal = (integer)llList2String(pData, 2);

                if (anoVal < 2024 || mesVal < 1 || mesVal > 12 || diaVal < 1 || diaVal > 31)
                {
                    llOwnerSay("❌ ERRO: Data inválida.");
                    llTextBox(id, "Digite uma NOVA DATA válida (DD/MM/AAAA):", canalFluxo);
                    return;
                }

                etapa = 10;
                llTextBox(id, "Digite o NOVO HORÁRIO no formato HH:MM:", canalFluxo);
            }
            // EDIÇÃO - 4: Novo Horário
            else if (etapa == 10)
            {
                tempHora = llStringTrim(message, STRING_TRIM);
                list pHora = llParseString2List(tempHora, [":"], []);
                if (llGetListLength(pHora) != 2)
                {
                    llOwnerSay("❌ ERRO: Formato de horário incorreto! Use HH:MM.");
                    llTextBox(id, "Digite o NOVO HORÁRIO novamente (HH:MM):", canalFluxo);
                    return;
                }

                integer horaVal = (integer)llList2String(pHora, 0);
                integer minVal = (integer)llList2String(pHora, 1);
                if (horaVal < 0 || horaVal > 23 || minVal < 0 || minVal > 59)
                {
                    llOwnerSay("❌ ERRO: Horário inválido.");
                    llTextBox(id, "Digite um NOVO HORÁRIO válido (HH:MM):", canalFluxo);
                    return;
                }

                integer testeTemp = checarValidadeTimestamp(tempDia, tempHora);
                if (testeTemp == -1)
                {
                    llOwnerSay("❌ ERRO NA EDIÇÃO: A nova data/horário (" + tempDia + " às " + tempHora + ") já passou!");
                    llTextBox(id, "Digite um NOVO HORÁRIO futuro válido (HH:MM):", canalFluxo);
                    return;
                }
                else if (testeTemp == 0)
                {
                    llOwnerSay("❌ ERRO NA EDIÇÃO: Data ou horário inválidos.");
                    llTextBox(id, "Digite um NOVO HORÁRIO válido (HH:MM):", canalFluxo);
                    return;
                }

                etapa = 11;
                llDialog(id, "Nova antecedência para o alerta:", ["0", "15", "30", "60"], canalFluxo);
            }
            // EDIÇÃO - 5: Confirmação e Gravação Final
            else if (etapa == 11)
            {
                tempAntecedencia = (integer)message;
                integer timestampFinal = checarValidadeTimestamp(tempDia, tempHora);

                if (timestampFinal <= 0)
                {
                    llOwnerSay("❌ Erro temporal na edição.");
                    etapa = 0;
                    return;
                }

                string novoRegistro = tempTitulo + "|" + tempTipo + "|" + (string)timestampFinal + "|" + (string)tempAntecedencia;
                llLinksetDataWrite("evento_" + (string)idAlvoEdicao, novoRegistro);

                adicionarAoHistorico(tempTitulo, tempTipo, "✏️ Editado/Reagendado", timestampFinal);

                etapa = 0;
                atualizarTextoFlutuante();
                llOwnerSay("✅ Evento #" + (string)idAlvoEdicao + " atualizado com sucesso!");
            }
            
            // ZERAR TUDO - Validação de Confirmação
            else if (etapa == 12)
            {
                string resposta = llToUpper(llStringTrim(message, STRING_TRIM));
                if (resposta == "SIM")
                {
                    llLinksetDataReset();
                    llLinksetDataWrite("total_eventos", "0");
                    historicoCompromissos = "Nenhum histórico registrado.";
                    atualizarTextoFlutuante();
                    llOwnerSay("🗑️ Operação concluída: Agenda e histórico completamente limpos.");
                }
                else
                {
                    llOwnerSay("🛡️ Operação cancelada por segurança. Seus dados foram preservados.");
                }
                etapa = 0;
            }
        }
    }

    timer()
    {
        integer agora = llGetUnixTime();
        integer total = (integer)llLinksetDataRead("total_eventos");
        if (total <= 0) return;

        integer i = 1;
        while (i <= total)
        {
            string dados = llLinksetDataRead("evento_" + (string)i);
            if (dados != "")
            {
                list partes = llParseString2List(dados, ["|"], []);
                string titulo = llList2String(partes, 0);
                string tipo = llList2String(partes, 1);
                integer timestamp = (integer)llList2String(partes, 2);
                integer antecedenciaMin = (integer)llList2String(partes, 3);

                integer momentoAlarme = timestamp - (antecedenciaMin * 60);

                if (agora >= momentoAlarme && agora < (momentoAlarme + 60))
                {
                    if (antecedenciaMin > 0)
                    {
                        llOwnerSay("🔔 LEMBRETE ANTECIPADO!\nO compromisso \"" + titulo + "\" (" + tipo + ") começa em " + (string)antecedenciaMin + " minutos!");
                    }
                    else
                    {
                        llOwnerSay("🔔 ALERTA DE COMPROMISSO!\nO compromisso \"" + titulo + "\" (" + tipo + ") está acontecendo agora!");
                    }
                }

                if (agora >= timestamp && tipo != "Aniversario")
                {
                    adicionarAoHistorico(titulo, tipo, "✔ Realizado", timestamp);
                    llLinksetDataDelete("evento_" + (string)i);
                    atualizarTextoFlutuante();
                }
            }
            i++;
        }
    }
}