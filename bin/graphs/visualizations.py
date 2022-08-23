# Libraries

# datta processing
import pandas as pd
import numpy as np

# visualizations
import plotly.graph_objects as go
import plotly.express as px

from load_data.load_data import LoadData


template = "simple_white"
results_path = "./results"
data = LoadData(results_path)
data.loadConsensus(), data.loadFeatMapsData(), data.loadMSDF()


##############################################################################
#############                 Consensus Graphs           #####################
##############################################################################


def init_consensus_graph():   
    fig = px.scatter(
                    data.consensus_df, 
                    x="RT", 
                    y="mz",
                    marginal_x="histogram", 
                    marginal_y="histogram",
                    height=600, width=800,
                    template=template
                )

    fig.update_layout(
                    showlegend=False,
                    title_text=f"RT vs MZ", 
                    title_x=0.5
                )

    return fig


def create_consensus_graph(df1, df2, sample_name):

    fig = px.scatter(
                df1, 
                x="RT", 
                y="mz",
                marginal_x="histogram", 
                marginal_y="histogram", 
                color=sample_name,
                height=600, width=800,
                template=template
            )

    fig.add_trace(
                go.Scatter(
                x=df2["RT"],
                y=df2["mz"],
                mode='markers',
                marker=dict(color="rgb(255,255,255)", line=dict(width=1, color='Grey'))
                
            ))

    fig.update_layout(
                    showlegend=False,
                    title_text=f"RT vs MZ by intensity on {sample_name}", 
                    title_x=0.5
                )

    fig.layout.coloraxis.colorbar.title = 'Intensity'

    return fig


##############################################################################
#############                   MS1 Graphs               #####################
##############################################################################


def create_ms1_grpah(feat_maps_df):
    
    # cond_to_filter = feat_maps_df["MS2_spectra_array"].apply(lambda x: len(x)>0)
    # filtered_df = feat_maps_df[cond_to_filter]

    fig = px.line(
            feat_maps_df, 
            x="mz", 
            y="intensity",
            height=500, width=900,
            template = template,
            hover_name = feat_maps_df.index
        )

    # fig.add_trace(
    #             go.Scatter(
    #             x=filtered_df["mz"],
    #             y=filtered_df["intensity"],
    #             mode='markers',
    #             marker=dict(color="rgb(255,255,255)", line=dict(width=1, color='Grey'))
    #         ))


    fig.update_layout(
            showlegend=False,
            title_text=f"mz vs intensity", 
            title_x=0.5
        )

    fig.update_traces(customdata=feat_maps_df.index)

    return fig 


##############################################################################
#############                   MS2 Graphs               #####################
##############################################################################


def create_ms2_graph(index_list, sample_name):

    data_fig = []
    for index in index_list:
        rt = data.dct_ms_df[sample_name][index]["RT"]
        mz_int_data = data.dct_ms_df[sample_name][index]["mz_int_data"]

        trace = go.Line(
            x = mz_int_data["mz"],
            y = mz_int_data["intensity"],
            name = rt
        )
        data_fig.append(trace)

    fig = go.Figure(data_fig)
    
    fig.update_layout(
        template=template, 
        title="MS2",
        legend_title="Retention Time",
        title_text= f"MZ vs intensity {sample_name}", 
        title_x=0.5,
        height=500, width=900,
        )

    return fig
