// Calculadora Simples com Porcentagem e Visor Otimizado (Sem casas decimais desnecessárias)
integer CANAL_MENU = -888877;
integer listener_handle;

string estado_atual = "";
float acumulado = 0.0;
string operacao = "";

// Função auxiliar para formatar números inteiros sem ".00"
string formatar_visor(float valor)
{
    // Se o número for inteiro (ex: 5.0), remove as casas decimais e exibe apenas 5
    if (valor == (integer)valor) {
        return (string)((integer)valor);
    }
    return (string)valor;
}

// Menu 1: Números de 0 a 6
abrir_menu_num1(key user)
{
    llListenRemove(listener_handle);
    listener_handle = llListen(CANAL_MENU, "", user, "");
    
    string visor = "0";
    if (estado_atual != "") {
        visor = estado_atual;
    }
    
    if (acumulado != 0.0) {
        visor = visor + " (Ant: " + formatar_visor(acumulado) + " " + operacao + ")";
    }
    
    llDialog(user, "\n[Visor: " + visor + "]\nEscolha:", 
             ["0", "1", "2", "3", "4", "5", "6", "Mais", "C", "Sair"], CANAL_MENU);
}

// Menu 2: Números finais (7 a 9), Ponto, Operações Básicas e Porcentagem (%)
abrir_menu_num2(key user)
{
    llListenRemove(listener_handle);
    listener_handle = llListen(CANAL_MENU, "", user, "");
    
    string visor = "0";
    if (estado_atual != "") {
        visor = estado_atual;
    }
    
    if (acumulado != 0.0) {
        visor = visor + " (Ant: " + formatar_visor(acumulado) + " " + operacao + ")";
    }
    
    llDialog(user, "\n[Visor: " + visor + "]\nOperações:", 
             ["7", "8", "9", ".", "+", "-", "*", "/", "%", "=", "Voltar", "Sair"], CANAL_MENU);
}

default
{
    state_entry()
    {
        llOwnerSay("Calculadora pronta! Clique no objeto para abrir.");
    }

    touch_start(integer total_number)
    {
        key user = llDetectedKey(0);
        if (user == llGetOwner()) {
            abrir_menu_num1(user);
        } else {
            llInstantMessage(user, "Apenas o dono pode usar esta calculadora.");
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel != CANAL_MENU) return;
        
        if (message == "Sair") {
            llListenRemove(listener_handle);
            return;
        }
        
        if (message == "Voltar" || message == "Mais") {
            if (message == "Voltar") {
                abrir_menu_num1(id);
            } else {
                abrir_menu_num2(id);
            }
            return;
        }
        
        // Digitar números ou ponto decimal
        if (message == "0" || message == "1" || message == "2" || message == "3" || 
            message == "4" || message == "5" || message == "6" || message == "7" || 
            message == "8" || message == "9" || message == ".") 
        {
            estado_atual = estado_atual + message;
            
            if (message == "7" || message == "8" || message == "9" || message == ".") {
                abrir_menu_num2(id);
            } else {
                abrir_menu_num1(id);
            }
        }
        // Operadores Básicos (+, -, *, /)
        else if (message == "+" || message == "-" || message == "*" || message == "/") 
        {
            if (estado_atual != "") {
                acumulado = (float)estado_atual;
                operacao = message;
                estado_atual = "";
            }
            abrir_menu_num2(id);
        }
        // Operação de Porcentagem (%)
        else if (message == "%")
        {
            if (estado_atual != "") {
                float valor_atual = (float)estado_atual;
                
                if (operacao == "+" || operacao == "-") {
                    valor_atual = acumulado * (valor_atual / 100.0);
                } 
                else if (operacao == "*" || operacao == "/") {
                    valor_atual = valor_atual / 100.0;
                } 
                else {
                    valor_atual = valor_atual / 100.0;
                }
                
                estado_atual = formatar_visor(valor_atual);
            }
            abrir_menu_num2(id);
        }
        // Botão de Igual (=)
        else if (message == "=") 
        {
            if (operacao != "" && estado_atual != "") {
                float val2 = (float)estado_atual;
                
                if (operacao == "+") {
                    acumulado = acumulado + val2;
                }
                else if (operacao == "-") {
                    acumulado = acumulado - val2;
                }
                else if (operacao == "*") {
                    acumulado = acumulado * val2;
                }
                else if (operacao == "/") {
                    if (val2 != 0.0) {
                        acumulado = acumulado / val2;
                    } else {
                        llOwnerSay("ERRO: Divisão por zero.");
                    }
                }
                
                estado_atual = formatar_visor(acumulado);
                operacao = "";
            }
            abrir_menu_num2(id);
        }
        // Botão Limpar (C)
        else if (message == "C") 
        {
            estado_atual = "";
            acumulado = 0.0;
            operacao = "";
            abrir_menu_num1(id);
        }
    }
}