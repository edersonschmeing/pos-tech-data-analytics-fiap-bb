import streamlit as st
import pandas as pd
import numpy as np
import yfinance as yf
import joblib
import json
import plotly.express as px
import ta
import yfinance as yf
import xgboost as xgb
from datetime import timedelta
from sklearn.preprocessing import StandardScaler


st.set_page_config(
    page_title="Predição de Tendência - BOVA11",
    layout="wide"
)

st.title("Predição de Tendência do BOVA11")
st.caption("Modelo de Machine Learning para previsão de movimento futuro")
st.caption("Treinado com dados do yfinance de 01/07/2021 à 30/06/2025")


def carregar_recursos():
    modelo = joblib.load("modelo_bova11_2021_07_01_a_2025_06_30.pkl")
    scaler = joblib.load("scaler_bova11_2021_07_01_a_2025_06_30.pkl")
    
    with open("bova11_2021_07_01_a_2025_06_30.json") as f:
        metrics = json.load(f)
    return modelo, scaler, metrics

modelo, scaler, metrics = carregar_recursos()

st.subheader("Performance do Modelo")
c1, c2, c3, c4 = st.columns(4)
c1.metric("Accuracy", f"{metrics['accuracy']:.2%}")
c2.metric("Precision", f"{metrics['precision']:.2%}")
c3.metric("Recall", f"{metrics['recall']:.2%}")
c4.metric("F1-score", f"{metrics['f1_score']:.2%}")


def criar_atributos(df):
    df = df.copy()
    
    df['RSI_14'] = ta.momentum.RSIIndicator(df['fechamento_ajustado'], window=14).rsi()
    df['MACD_14'] = ta.trend.MACD(df['fechamento_ajustado'], window_slow=14).macd() ## window=14
  
    df['BB_position_20'] = ta.volatility.BollingerBands(df['fechamento_ajustado'], window=20).bollinger_pband()
  
    df['ATR_14'] = ta.volatility.AverageTrueRange(df["maximo"], 
                                                  df["minimo"], 
                                                  df["fechamento_ajustado"], 
                                                  window=14).average_true_range()
    
    df['volatility_20'] = df['fechamento_ajustado'].pct_change().rolling(20).std()

    df['SMA_7'] = ta.trend.sma_indicator(df['fechamento_ajustado'], window=7)
    df['SMA_14'] = ta.trend.sma_indicator(df['fechamento_ajustado'], window=14)
    df['SMA_27'] = ta.trend.sma_indicator(df['fechamento_ajustado'], window=27)
    
    df['volume_MA_20'] = df['volume'].rolling(20).mean()
    df['volume_ratio'] = df['volume'] / df['volume_MA_20']
    
    for atrasos in range(1, 5):
        df[f'atrasos_{atrasos}'] = df['fechamento_ajustado'].pct_change(atrasos)

    return df
    
data = st.date_input("Selecione a data base")

data_inicial = data - timedelta(days=60)
data_final = data + timedelta(days=1)
df = yf.download('BOVA11.SA', start=data_inicial, end=data_final, interval='1d', auto_adjust=False)
df.columns = df.columns.get_level_values(0)
df.columns.name = None

if df.empty:
    st.error("Erro ao baixar dados.")
    st.stop()

df.rename(columns={'Date': 'data',
                   'Close': 'fechamento',
                   'Adj Close': 'fechamento_ajustado',
                   'High': 'maximo',
                   'Low': 'minimo',
                   'Open': 'abertura',
                   'Volume': 'volume'},
                   inplace=True)


df.dropna(inplace=True)

df_feat = criar_atributos(df)
df_feat.dropna(inplace=True)

try:
    linha = df_feat.loc[str(data)]
except KeyError:
    st.warning("A data escolhida não é um pregão.")
    st.stop()


features = ["RSI_14", "MACD_14",
            "SMA_7", "SMA_14", "SMA_27",
            "volatility_20",
            "atrasos_4", "atrasos_3", "atrasos_2", "atrasos_1",
            "BB_position_20", "ATR_14",
            "volume_ratio"]

 
X = linha[features].values.reshape(1, -1)
X_scaled = scaler.transform(X)

pred = modelo.predict(X_scaled)[0]
prob = modelo.predict_proba(X_scaled)[0].max()
print(pred)
st.success(
    f"Previsão para o próximo pregão: "
    f"**{'ALTA' if pred == 1 else 'BAIXA'}**"
)
st.caption(f"Confiança do modelo: {prob:.2%}")


## Gráfico principal: Preço + Médias Móveis + Data da Previsão
st.subheader("Análise Temporal do BOVA11")
df_plot = df_feat.loc[:str(data)].tail(60)

fig_preco = px.line(
    df_plot,
    x=df_plot.index,
    y=["fechamento_ajustado", "SMA_7", "SMA_14", "SMA_27"],
    labels={"value": "Preço", "index": "Data"},
    title="Preço do BOVA11 e Médias Móveis"
)

fig_preco.update_layout(
    shapes=[
        dict(
            type="line",
            xref="x",
            yref="paper",
            x0=str(data),
            x1=str(data),
            y0=0,
            y1=1,
            line=dict(color="red", dash="dash")
        )
    ],
    annotations=[
        dict(
            x=str(data),
            y=1,
            xref="x",
            yref="paper",
            text="Data da Previsão",
            showarrow=False,
            yanchor="bottom",
            font=dict(color="red")
        )
    ]
)
st.plotly_chart(fig_preco, use_container_width=True)


## Indicadores Técnicos (RSI + MACD)
st.subheader("Indicadores Técnicos (RSI + MACD)")
col1, col2 = st.columns(2)

with col1:
    fig_rsi = px.line(
        df_plot,
        x=df_plot.index,
        y="RSI_14",
        title="RSI (14)"
    )
    fig_rsi.add_hline(y=70, line_dash="dot", line_color="red")
    fig_rsi.add_hline(y=30, line_dash="dot", line_color="green")
    st.plotly_chart(fig_rsi, use_container_width=True)

with col2:
    fig_macd = px.line(
        df_plot,
        x=df_plot.index,
        y="MACD_14",
        title="MACD"
    )
    fig_macd.add_hline(y=0, line_dash="dash")
    st.plotly_chart(fig_macd, use_container_width=True)


##Gráfico de Volatilidade (Risco)
fig_vol = px.line(
    df_plot,
    x=df_plot.index,
    y="volatility_20",
    title="Volatilidade Histórica (20 dias)",
    labels={"volatility_20": "Volatilidade"}
)
st.plotly_chart(fig_vol, use_container_width=True)


##Explicação da decisão
st.subheader("Interpretação da Previsão")
if pred == 1:
    st.markdown("""
    **Tendência de ALTA identificada**

    O modelo detectou:
    - Médias móveis em inclinação positiva
    - Momentum favorável (RSI / MACD)
    - Estrutura recente de retornos positivos

    Indicação de continuação de movimento ascendente no próximo pregão.
    """)
else:
    st.markdown("""
    **Tendência de BAIXA identificada**

    O modelo detectou:
    - Enfraquecimento do momentum
    - Aumento de volatilidade
    - Retornos recentes negativos

    Indicação de possível correção ou continuação de queda no próximo pregão.
    """)


## Importância das Variáveis
st.subheader("Importância das Variáveis")
importancias = modelo.feature_importances_
df_imp = pd.DataFrame({
    "Variáveis": features,
    "Importância": importancias
}).sort_values(by="Importância", ascending=False)

fig_imp = px.bar(
    df_imp,
    x="Importância",
    y="Variáveis",
    orientation="h",
    title="Importância das Variáveis no Modelo"
)
st.plotly_chart(fig_imp, use_container_width=True)
