library(tidyverse)
library(theft)
library(feather)
library(glue)
library(reticulate)
library(cowplot)
library(ggridges)
theme_set(theme_cowplot())
library(dendextend)
library(grid)
library(ComplexHeatmap)
library(patchwork)
library(ggseg)
library(GGally)

python_to_use <- "/path/to/your/preferred/installation/of/python3"
reticulate::use_python(python_to_use)

library(reticulate)

# Import pyarrow.feather as pyarrow_feather
pyarrow_feather <- import("pyarrow.feather")

# DIY rlist::list.append
list.append <- function (.data, ...) 
{
  if (is.list(.data)) {
    c(.data, list(...))
  }
  else {
    c(.data, ..., recursive = FALSE)
  }
}

################################################################################

# Load SPI and module colours
SPI_HClust_Modules <- read.csv("../data/SPI_modules.csv")
SPI_Literature_Modules <- read.csv("../data/SPI_literature_categories.csv")
SPI_module_colours <- read.csv("../data/SPI_module_colours.csv") %>%
  dplyr::select(-X)

# BasicMotions
BasicMotions_data_path <- "../data/pyspi_paper/BasicMotions" # Change this to wherever you store your data for this repo
BasicMotions_metadata = pyarrow_feather$read_feather(glue("{BasicMotions_data_path}/BasicMotions_sample_metadata.feather"))
BasicMotions_TS_data <- pyarrow_feather$read_feather(glue("{BasicMotions_data_path}/processed_data/BasicMotions_TS.feather"))
BasicMotions_pyspi_data = pyarrow_feather$read_feather(glue("{BasicMotions_data_path}/processed_data/BasicMotions_pyspi_filtered_for_classification.feather")) %>%
  left_join(., BasicMotions_metadata, by="Sample_ID")
BasicMotions_classes = as.character(unique(BasicMotions_pyspi_data$group))

BasicMotions_main_SPI_wise <- pyarrow_feather$read_feather(glue("{BasicMotions_data_path}/processed_data/BasicMotions_main_SPI_wise_acc.feather"))
BasicMotions_main_SPI_wise_mean <- BasicMotions_main_SPI_wise %>%
  group_by(SPI) %>%
  summarise(Mean_Accuracy = mean(Accuracy, na.rm = T),
            SD_Accuracy = sd(Accuracy, na.rm=T))
BasicMotions_null_SPI_wise <- pyarrow_feather$read_feather(glue("{BasicMotions_data_path}/processed_data/BasicMotions_null_SPI_wise_acc.feather"))
BasicMotions_main_full <- pyarrow_feather$read_feather(glue("{BasicMotions_data_path}/processed_data/BasicMotions_main_full_acc.feather"))
BasicMotions_main_full_mean <- BasicMotions_main_full %>%
  summarise(Mean_Accuracy = mean(Accuracy, na.rm = T),
            SD_Accuracy = sd(Accuracy, na.rm=T))
BasicMotions_null_full <- pyarrow_feather$read_feather(glue("{BasicMotions_data_path}/processed_data/BasicMotions_null_full_acc.feather"))
BasicMotions_null_SPI_wise_top_quantile <- quantile(BasicMotions_null_SPI_wise$Null_Accuracy, probs = c(1-(0.05/212)))

# SelfRegulationSCP1
EEG_data_path <- "../data/pyspi_paper/SelfRegulationSCP1" # Change this to wherever you store your data for this repo
EEG_metadata = pyarrow_feather$read_feather(glue("{EEG_data_path}/SelfRegulationSCP1_sample_metadata.feather"))
EEG_TS_data <- pyarrow_feather$read_feather(glue("{EEG_data_path}/processed_data/SelfRegulationSCP1_TS.feather"))
EEG_pyspi_data = pyarrow_feather$read_feather(glue("{EEG_data_path}/processed_data/SelfRegulationSCP1_pyspi_filtered.feather")) %>%
  left_join(., EEG_metadata, by="Sample_ID") %>%
  dplyr::rename("group" = "cortical")
EEG_classes = as.character(unique(EEG_pyspi_data$group))

EEG_main_SPI_wise <- pyarrow_feather$read_feather(glue("{EEG_data_path}/processed_data/SelfRegulationSCP1_main_SPI_wise_acc.feather"))
EEG_main_SPI_wise_mean <- EEG_main_SPI_wise %>%
  group_by(SPI) %>%
  summarise(Mean_Accuracy = mean(Accuracy, na.rm = T),
            SD_Accuracy = sd(Accuracy, na.rm=T))
EEG_null_SPI_wise <- pyarrow_feather$read_feather(glue("{EEG_data_path}/processed_data/SelfRegulationSCP1_null_SPI_wise_acc.feather"))
EEG_main_full <- pyarrow_feather$read_feather(glue("{EEG_data_path}/processed_data/SelfRegulationSCP1_main_full_acc.feather"))
EEG_main_full_mean <- EEG_main_full %>%
  summarise(Mean_Accuracy = mean(Accuracy, na.rm = T),
            SD_Accuracy = sd(Accuracy, na.rm=T))
EEG_null_full <- pyarrow_feather$read_feather(glue("{EEG_data_path}/processed_data/SelfRegulationSCP1_null_full_acc.feather"))
EEG_null_SPI_wise_top_quantile <- quantile(EEG_null_SPI_wise$Null_Accuracy, probs = c(1-(0.05/212)))

# Rest versus movie watching fMRI
restfilm_data_path <- "../data/pyspi_paper/Rest_vs_Film_fMRI/" # Change this to wherever you store your data for this repo
restfilm_pyspi_data = pyarrow_feather$read_feather(glue("{restfilm_data_path}/processed_data/Rest_vs_Film_fMRI_pyspi_filtered.feather")) 
restfilm_TS_data <- pyarrow_feather$read_feather(glue("{restfilm_data_path}/processed_data/Rest_vs_Film_fMRI_fMRI_TS_Yeo7.feather"))
restfilm_metadata = pyarrow_feather$read_feather(glue("{restfilm_data_path}/Rest_vs_Film_fMRI_metadata.feather")) %>%
  semi_join(., restfilm_pyspi_data %>% dplyr::rename("Unique_ID" = "Sample_ID"))
restfilm_pyspi_data <- restfilm_pyspi_data %>%
  dplyr::rename("Unique_ID" = "Sample_ID") %>%
  left_join(., restfilm_metadata, by="Unique_ID") %>%
  dplyr::rename("group" = "Scan_Type")

restfilm_main_SPI_wise <- pyarrow_feather$read_feather(glue("{restfilm_data_path}/processed_data/Rest_vs_Film_fMRI_main_SPI_wise_acc.feather"))
restfilm_main_SPI_wise_mean <- restfilm_main_SPI_wise %>%
  group_by(SPI) %>%
  summarise(Mean_Accuracy = mean(Accuracy, na.rm = T),
            SD_Accuracy = sd(Accuracy, na.rm=T))
restfilm_null_SPI_wise <- pyarrow_feather$read_feather(glue("{restfilm_data_path}/processed_data/Rest_vs_Film_fMRI_null_SPI_wise_acc.feather"))
restfilm_main_full <- pyarrow_feather$read_feather(glue("{restfilm_data_path}/processed_data/Rest_vs_Film_fMRI_main_full_acc.feather"))
restfilm_main_full_mean <- restfilm_main_full %>%
  summarise(Mean_Accuracy = mean(Accuracy, na.rm = T),
            SD_Accuracy = sd(Accuracy, na.rm=T))
restfilm_null_full <- pyarrow_feather$read_feather(glue("{restfilm_data_path}/processed_data/Rest_vs_Film_fMRI_null_full_acc.feather"))
restfilm_null_SPI_wise_top_quantile <- quantile(restfilm_null_SPI_wise$Null_Accuracy, probs = c(1-(0.05/212)))


################################################################################
# Function to calculate p-values relative to null
bonferroni_alpha = 0.05 / 212
calculate_p_values <- function(main_res, null_Accuracy_df) {
  null_acc <- null_Accuracy_df$Null_Accuracy
  p_res <- main_res %>%
    rowwise() %>%
    mutate(p_value = 1 - sum(Mean_Accuracy > null_acc) / length(null_acc)) %>%
    ungroup() %>%
    mutate(p_value_bonferroni = p.adjust(p_value, method="bonferroni"),
           significant = p_value_bonferroni < 0.05)
  
  return(p_res)
}

# BasicMotions
BasicMotions_SPI_wise_p_values <- calculate_p_values(main_res = BasicMotions_main_SPI_wise_mean,
                                           null_Accuracy_df = BasicMotions_null_SPI_wise)

BasicMotions_full_p_values <- calculate_p_values(main_res = BasicMotions_main_full_mean,
                                       null_Accuracy_df = BasicMotions_null_full)

# SelfRegulationSCP
EEG_SPI_wise_p_values <- calculate_p_values(main_res = EEG_main_SPI_wise_mean,
                                            null_Accuracy_df = EEG_null_SPI_wise)

EEG_full_p_values <- calculate_p_values(main_res = EEG_main_full_mean,
                                        null_Accuracy_df = EEG_null_full)

# Rest vs Film 
restfilm_SPI_wise_p_values <- calculate_p_values(main_res = restfilm_main_SPI_wise_mean,
                                                 null_Accuracy_df = restfilm_null_SPI_wise)

restfilm_full_p_values <- calculate_p_values(main_res = restfilm_main_full_mean,
                                             null_Accuracy_df = restfilm_null_full)

################################################################################
# Plot example time-series per class
icefire <- colorRampPalette(c("#C0E1D9", "#72A9CA", "#3875CF", "#42407A", 
                              "#22222C", "#5D2935", "#D34B36", "#F29257", 
                              "#FCC79C"))

# BasicMotions
set.seed(127)
BasicMotions_random_samples <- BasicMotions_TS_data %>%
  group_by(activity) %>%
  sample_n(1) %>%
  pull(Sample_ID) 
BasicMotions_TS_data %>%
  filter(Sample_ID %in% BasicMotions_random_samples) %>%
  mutate(timepoint_num = as.factor(timepoint_num),
         signal_z = case_when(signal_z > 2 ~ 2.5,
                              signal_z < -2 ~ -2.5,
                              T ~ signal_z),
         Measurement = factor(Measurement, levels = rev(c("Accelerometer_x", "Accelerometer_y", "Accelerometer_z",
                                                          "Gyroscope_x", "Gyroscope_y", "Gyroscope_z")))) %>%
  rowwise() %>%
  mutate(activity = ifelse(activity == "Standing", "Resting", as.character(activity))) %>%
  ungroup() %>%
  mutate(activity = factor(activity, levels = c("Resting", "Walking", "Running", "Badminton"))) %>%
  ggplot(data=., mapping=aes(x=timepoint_num, y=Measurement, fill=signal_z)) +
  geom_raster() +
  facet_wrap(activity ~ ., ncol=1) +
  theme_void() +
  scale_color_gradientn(colors = icefire(50)) +
  scale_fill_gradientn(colors = icefire(50)) +
  theme(legend.position = "none",
        panel.spacing = unit(0.12, "lines"),
        strip.text.x = element_text(margin = margin(0, 4.4, 3, 4.4, "pt")),
        panel.grid.major = element_blank())

# SelfRegulationSCP1
set.seed(127)
EEG_random_samples <- EEG_TS_data %>%
  group_by(Sample_ID, cortical) %>%
  summarise(mean_z = mean(signal_z)) %>%
  ungroup() %>%
  group_by(cortical) %>%
  filter(mean_z == max(mean_z) | mean_z == min(mean_z)) %>%
  ungroup() %>%
  filter(mean_z > 0 & cortical == "positivity" | mean_z < 0 & cortical == "negativity") %>%
  pull(Sample_ID)
EEG_TS_data %>%
  filter(Sample_ID %in% EEG_random_samples,
         timepoint_num < 500) %>%
  mutate(timepoint_num = as.factor(timepoint_num)) %>%
  ggplot(data=., mapping=aes(x=timepoint_num, y=rev(Channel), fill=signal_z)) +
  geom_raster() +
  facet_grid(cortical ~ .) +
  theme_void() +
  scale_color_gradientn(colors = icefire(50)) +
  scale_fill_gradientn(colors = icefire(50)) +
  theme(legend.position = "none",
        panel.grid.major = element_blank(),
        strip.text = element_blank())

# Line plots
EEG_TS_data %>%
  filter(Sample_ID %in% EEG_random_samples,
         timepoint_num < 500,
         cortical == "positivity") %>%
  ggplot(data=., mapping=aes(x=timepoint_num, y=signal_z, group=Channel, color=Channel)) +
  facet_grid(Channel ~ ., scales="free") +
  geom_line(linewidth=1) +
  theme(legend.position="none") +
  scale_color_manual(values = viridis::viridis(7)) +
  theme_void() +
  theme(legend.position = "none",
        strip.text = element_blank())

# Rest vs Video fMRI
library(ggsegExtra)
library(ggsegYeo2011)

set.seed(27)
restfilm_random_sample <- sample(unique(restfilm_metadata$Sample_ID), 1)
restfilm_TS_data %>%
  filter(Sample_ID %in% restfilm_random_sample,
         Session_Number == "1",
         Scan_Type == "movie",
         timepoint<200) %>%
  mutate(Yeo_7_Networks_Bilateral = case_when(Yeo_7_Networks_Bilateral == "DorsalAttention" ~ "Dorsal Attention",
                                              Yeo_7_Networks_Bilateral == "VentralAttention" ~ "Salience / Ventral Attention",
                                              T ~ Yeo_7_Networks_Bilateral)) %>%
  ggplot(data=., mapping=aes(x=timepoint, y=Mean_BOLD_Signal, group=Yeo_7_Networks_Bilateral, color=Yeo_7_Networks_Bilateral)) +
  facet_grid(Yeo_7_Networks_Bilateral ~ ., scales="free") +
  geom_line(linewidth=1) +
  theme(legend.position="none") +
  scale_color_brain("yeo7", package="ggsegYeo2011") +
  theme_void() +
  theme(legend.position = "none",
        panel.spacing = unit(0.02, "lines"),
        strip.text = element_blank())
ggsave(glue("{plot_path}/Rest_vs_Film_fMRI_Example_movie_TS.svg"), 
       width=4, height=2, units="in", dpi=300)
restfilm_TS_data %>%
  filter(Sample_ID %in% restfilm_random_sample,
         Session_Number == "1",
         Scan_Type == "rest",
         timepoint<200) %>%
  mutate(Yeo_7_Networks_Bilateral = case_when(Yeo_7_Networks_Bilateral == "DorsalAttention" ~ "Dorsal Attention",
                                              Yeo_7_Networks_Bilateral == "VentralAttention" ~ "Salience / Ventral Attention",
                                              T ~ Yeo_7_Networks_Bilateral)) %>%
  ggplot(data=., mapping=aes(x=timepoint, y=Mean_BOLD_Signal, group=Yeo_7_Networks_Bilateral, color=Yeo_7_Networks_Bilateral)) +
  facet_grid(Yeo_7_Networks_Bilateral ~ ., scales="free") +
  geom_line(linewidth=1) +
  theme(legend.position="none") +
  scale_color_brain("yeo7", package="ggsegYeo2011") +
  theme_void() +
  theme(legend.position = "none",
        panel.spacing = unit(0.02, "lines"),
        strip.text = element_blank())


################################################################################
# Plot histograms
plot_SPI_histogram <- function(p_value_df, all_SPI_acc, num_bins, x_min, x_max, xlab, legend_x, legend_y, SPI_to_plot=NULL, SPI_to_plot_name=NULL) {

  p <- p_value_df %>%
    mutate(Significance = ifelse(significant, "Significant SPIs", "Not Sig")) %>%
    ggplot(data=., mapping=aes(x=100*Mean_Accuracy, fill=Significance)) +
    xlab(xlab) +
    ylab("Proportion") +
    geom_histogram(color=NA, bins=num_bins, aes(y=after_stat(count)/sum(after_stat(count))),
                   position = "identity") +
    scale_fill_manual(values = c("Significant SPIs" = "skyblue",
                                 "Not Sig" = "gray80"),
                      limits = c("Significant SPIs"),
                      na.value = "gray80") +
    scale_x_continuous(expand = c(0.01, 0.01), limits = c(x_min, x_max)) +
    scale_y_continuous(expand = c(0, 0),
                       breaks = c(0.00, 0.05, 0.10),
                       labels = c("0.00", "0.05", "0.10")) +
    geom_vline(linewidth=1, key_glyph = "path",
               aes(xintercept = all_SPI_acc,
                   color="All SPIs")) +
    scale_color_manual(values = c("red")) +
    theme(legend.position=c(legend_x, legend_y),
          legend.title = element_blank(),
          legend.spacing.y = unit(-0.6, "cm"))
  if (!is.null(SPI_to_plot) ) {
    SPI_to_plot_val = 100*(subset(p_value_df, SPI==SPI_to_plot) %>% pull(Mean_Accuracy))
    p <- p + geom_vline(linewidth=1, key_glyph="path", aes(xintercept = SPI_to_plot_val,
                                                           color = SPI_to_plot_name)) +
      scale_color_manual(values = c("red", "black")) +
      theme(legend.spacing.y = unit(-0.8, "cm"))
  }
  
  return(p)
}

# BasicMotions
plot_SPI_histogram(p_value_df = BasicMotions_SPI_wise_p_values, 
                   all_SPI_acc = 100*BasicMotions_full_p_values$Mean_Accuracy, 
                   x_min = 20, x_max = 100, num_bins = 35, xlab="Average accuracy (%)",
                   legend_x = 0.05, legend_y = 0.8)

# SelfRegulationSCP1
plot_SPI_histogram(p_value_df = EEG_SPI_wise_p_values, 
                   all_SPI_acc = 100*EEG_full_p_values$Mean_Accuracy, 
                   x_min = 45, x_max = 75, num_bins=28, xlab="Average accuracy (%)",
                   legend_x = 0.05, legend_y = 0.8)

# Rest_vs_Film
plot_SPI_histogram(p_value_df = restfilm_SPI_wise_p_values, 
                   all_SPI_acc = 100*restfilm_full_p_values$Mean_Accuracy, 
                   x_min = 40, x_max = 100, num_bins=29, xlab="Average accuracy (%)",
                   legend_x = 0.05, legend_y = 0.7,
                   SPI_to_plot = "cov_EmpiricalCovariance",
                   SPI_to_plot_name = "Pearson correlation")

################################################################################
# Pairwise top feature violin plots
plot_most_discriminative_feature_pair <- function(pyspi_data, 
                                                  group_classes,
                                                  this_SPI,
                                                  ylabel,
                                                  violin_colors = c("#B384EE", "#E087F8")) {
  group_combos <- as.data.frame(t(combn(unique(group_classes), 2))) %>%
    mutate(group_pair = paste0(V1, "__", V2), .keep="unused") %>%
    pull(group_pair)
  
  node_combos <- as.data.frame(t(combn(unique(c(pyspi_data$Node_from,pyspi_data$Node_to)),2))) %>%
    mutate(node_pair_1 = paste0(V1, "__", V2), 
           node_pair_2 = paste0(V2, "__", V1), 
           .keep="unused") %>%
    pivot_longer(cols =c(node_pair_1, node_pair_2)) %>%
    pull(value)
  
  # Run each pairwise t-statistics
  t_stat_list <- list()
  i = 0
  for (group_com in group_combos) {
    group_one = str_split(group_com, "__")[[1]][1]
    group_two = str_split(group_com, "__")[[1]][2]
    for (node_com in node_combos) {
      node_one <- str_split(node_com, "__")[[1]][1]
      node_two <- str_split(node_com, "__")[[1]][2]
      if (node_one != node_two) {
        i <- i + 1
        
        combo_data <- pyspi_data %>%
          filter(SPI == this_SPI) %>%
          mutate(Node_Combo = paste0(Node_from, "__", Node_to)) %>%
          filter(Node_from == node_one,
                 Node_to == node_two,
                 group %in% c(group_one, 
                              group_two))
        
        res = data.frame(Group_Combo = group_com, 
                         Node_Combo = node_com,
                         T_stat = t.test(value ~ group, data = combo_data)$statistic)
        
        t_stat_list[[i]] <- res
      }
    }
  }
  t_stat_df <- do.call(plyr::rbind.fill, t_stat_list)
  
  # Find largest magnitude t stat
  top_t_stat <- t_stat_df %>%
    ungroup() %>%
    filter(abs(T_stat) == max(abs(T_stat)))
  top_group_combo <- str_split(top_t_stat$Group_Combo, "__")[[1]]
  top_node_combo <- str_split(top_t_stat$Node_Combo, "__")[[1]]
  
  print(glue("Top group combo: {top_group_combo}"))
  print(glue("Top node combo: {top_node_combo}"))
  
  # Plot violins
  p <- pyspi_data %>%
    filter(SPI == this_SPI,
           group %in% top_group_combo,
           Node_from == top_node_combo[1],
           Node_to == top_node_combo[2]) %>%
    ggplot(data=., mapping=aes(x=group, y=value, fill=group)) +
    ylab(ylabel) +
    geom_violin() +
    geom_boxplot(width=0.1, fill="gray40") +
    scale_fill_manual(values = violin_colors) +
    theme(axis.title.x = element_blank(),
          axis.title.y = element_text(size=15),
          axis.text.x = element_text(size=15)) +
    theme(legend.position = "none")
  
  return(p)
  
}

# # Find all pairwise combinations of activities
plot_most_discriminative_feature_pair(pyspi_data = BasicMotions_pyspi_data,
                                      group_classes = BasicMotions_classes,
                                      this_SPI = "cce_kozachenko",
                                      ylabel = "Causally conditioned\nentropy, Kozachenko",
                                      violin_colors = c("#B384EE", "#3564A1"))

# EEG SelfRegulationSCP1
plot_most_discriminative_feature_pair(pyspi_data = EEG_pyspi_data,
                                      group_classes = EEG_classes,
                                      this_SPI = "cce_gaussian",
                                      ylabel = "Causally conditioned\nentropy, Gaussian",
                                      violin_colors = c(alpha("#3068B8", 0.7), alpha("#BD0005", 0.7)))

# Rest vs Film
plot_most_discriminative_feature_pair(pyspi_data = restfilm_pyspi_data,
                                      group_classes = c("movie", "rest"),
                                      this_SPI = "reci",
                                      ylabel = "RECI",
                                      violin_colors = c("#CC87F8", "#97C777"))


################################################################################
# Plot performance across literature modules
literature_category_order <- c('basic','distance','causal','infotheory','spectral','misc')

plot_literature_modules <- function(p_value_df, 
                                    y_min, y_max, 
                                    ylab = "Average accuracy (%)",
                                    full_SPI_acc) {
  set.seed(127)
  p <- p_value_df %>%
    left_join(., SPI_Literature_Modules) %>%
    left_join(., SPI_module_colours %>% dplyr::rename("Literature_Module" = "Module") %>% 
                filter(Module_Type=="Literature")) %>%
    filter(!is.na(Literature_Module)) %>%
    mutate(Literature_Module = factor(Literature_Module, levels = literature_category_order)) %>%
    ggplot(data=., mapping=aes(x=Literature_Module, y=100*Mean_Accuracy)) +
    geom_violin(aes(fill=Colour), scale="width") +
    scale_fill_identity() +
    geom_jitter(fill=alpha("black", 0.5), color=alpha("black", 0.5), stroke=0.3, width=0.1, size=1) +
    scale_y_continuous(limits=c(y_min,y_max), expand=c(0,0)) +
    ylab(ylab) +
    geom_hline(yintercept = full_SPI_acc, color="red") +
    theme(legend.position="none",
          axis.title.y = element_text(size=11),
          axis.text.y = element_text(size=10),
          axis.title.x = element_blank(),
          axis.text.x = element_blank())
  return(p)
}

# BasicMotions
plot_literature_modules(p_value_df = BasicMotions_SPI_wise_p_values, 
                        y_min = 20, y_max = 100, 
                        ylab = "Average accuracy (%)",
                        full_SPI_acc = 100*BasicMotions_full_p_values$Mean_Accuracy)

# SelfRegulationSCP1
plot_literature_modules(p_value_df = EEG_SPI_wise_p_values, 
                        y_min = 46, y_max = 72, 
                        ylab = "Average accuracy (%)",
                        full_SPI_acc = 100*EEG_full_p_values$Mean_Accuracy)

# Rest vs Film
plot_literature_modules(p_value_df = restfilm_SPI_wise_p_values, 
                        y_min = 40, y_max = 100, 
                        null_quantile = 100*restfilm_null_SPI_wise_top_quantile,
                        ylab = "Average accuracy (%)",
                        full_SPI_acc = 100*restfilm_full_p_values$Mean_Accuracy)

################################################################################
# Plot performance across hclust modules
plot_hclust_modules <- function(p_value_df, 
                                y_min, y_max, 
                                null_quantile,
                                ylab = "Average accuracy (%)",
                                full_SPI_acc) {
  p <- p_value_df %>%
    left_join(., SPI_HClust_Modules) %>%
    left_join(., SPI_module_colours %>% 
                filter(Module_Type=="HClust")) %>%
    filter(!is.na(Module)) %>%
    ggplot(data=., mapping=aes(x=Module, y=100*Mean_Accuracy)) +
    geom_violin(aes(fill=Colour), scale="width", width=0.6) +
    scale_fill_identity() +
    geom_jitter(fill=alpha("black", 0.5), color=alpha("black", 0.5), stroke=0.3, width=0.1, size=0.75) +
    scale_y_continuous(limits=c(y_min,y_max), expand=c(0,0)) +
    ylab(ylab) +
    xlab("Module") +
    # geom_hline(yintercept = null_quantile, color="black") +
    geom_hline(yintercept = full_SPI_acc, color="red") +
    theme(legend.position="none",
          axis.title = element_text(size=11),
          axis.text.y = element_text(size=10),
          axis.text.x = element_text(size=8))
  
  return(p)
}

# BasicMotions
plot_hclust_modules(p_value_df = BasicMotions_SPI_wise_p_values, 
                    y_min = 20, y_max = 100, 
                    null_quantile = 100*BasicMotions_null_SPI_wise_top_quantile,
                    ylab = "Average accuracy (%)",
                    full_SPI_acc = 100*BasicMotions_full_p_values$Mean_Accuracy)

# SelfRegulationSCP1
plot_hclust_modules(p_value_df = EEG_SPI_wise_p_values, 
                    y_min = 46, y_max = 72, 
                    null_quantile = 100*EEG_null_SPI_wise_top_quantile,
                    ylab = "Average accuracy (%)",
                    full_SPI_acc = 100*EEG_full_p_values$Mean_Accuracy)

# Rest vs Film
plot_hclust_modules(p_value_df = restfilm_SPI_wise_p_values, 
                    y_min = 40, y_max = 100, 
                    null_quantile = 100*restfilm_null_SPI_wise_top_quantile,
                    ylab = "Average accuracy (%)",
                    full_SPI_acc = 100*restfilm_full_p_values$Mean_Accuracy)

################################################################################
# Plot Yeo atlas functional networks
ggseg(atlas = yeo7, mapping = aes(fill = region), hemisphere="left", color="gray30") +
  scale_fill_brain("yeo7", package = "ggsegYeo2011") +
  theme_cowplot() +
  labs(fill="Yeo 2011 Network") +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        axis.line = element_blank(),
        axis.ticks = element_blank(),
        legend.position = "bottom") +
  guides(fill = guide_legend(ncol = 1, title.position="top", title.hjust = 0.5))

# Control and ventralattention only to show next to violin plot
data.frame(region = c("Control", "Salience / Ventral Attention"),
           fill = c("Control", "Salience / Ventral Attention")) %>%
  ggplot() +
  geom_brain(atlas = yeo7, mapping=aes(fill=fill), hemi="left", color="gray30") +
  scale_fill_brain("yeo7", package = "ggsegYeo2011", na.value="white") +
  theme_void() +
  theme(legend.position="none")
ggsave(glue("{plot_path}/Rest_vs_Film_Yeo2011_Control_VentralAttention.svg"), width=3, height=1, units="in", dpi=300)

################################################################################
# Compare film fMRI SPI performance to Pearson correlation
restfilm_main_SPI_wise_mean %>%
  filter(Mean_Accuracy > Mean_Accuracy[SPI=="cov_EmpiricalCovariance"]) %>%
  write.csv(glue("{restfilm_data_path}/processed_data/SPIs_Beating_Pearson_Correlation.csv"),
            row.names = FALSE)


################################################################################
# Comparing SPIs across datasets
performance_across <- do.call(plyr::rbind.fill, list(BasicMotions_SPI_wise_p_values %>% mutate(Problem="Smartwatch activity"),
                                                     EEG_SPI_wise_p_values %>% mutate(Problem="EEG cursor movement"),
                                                     restfilm_SPI_wise_p_values %>% mutate(Problem="fMRI film"))) %>%
  group_by(Problem) %>%
  mutate(SPI_rank = rank(desc(Mean_Accuracy))) %>%
  dplyr::select(Problem, SPI, SPI_rank, Mean_Accuracy:significant) 

# Write to a CSV
performance_across %>%
  ungroup() %>% 
  mutate(Problem = factor(Problem, levels = c("Smartwatch activity",
                                              "EEG cursor movement",
                                              "fMRI film"))) %>%
  arrange(Problem, SPI_rank) %>%
  write.csv("~/data/pyspi_paper/SPI_performance_across_problems.csv", row.names = F)

performance_across %>%
  dplyr::select(SPI, Problem, Mean_Accuracy) %>%
  pivot_wider(id_cols = SPI, names_from = Problem, values_from = Mean_Accuracy) %>%
  dplyr::select(-SPI) %>%
  ggpairs(upper = list(continuous = wrap("cor", method= "spearman")))

SPI_ranks_across <- performance_across %>%
  ungroup() %>%
  group_by(SPI) %>%
  summarise(Mean_Rank = mean(SPI_rank),
            SD_Rank = sd(SPI_rank),
            max_diff = max(SPI_rank) - min(SPI_rank))