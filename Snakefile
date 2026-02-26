SAMPLE = "SRR2584857"
SUBSETS = ["2000000", "3000000", "4000000"]

rule all:
    input:
        expand(f"{SAMPLE}_quast.{{subset}}", subset=SUBSETS),
        expand(f"{SAMPLE}_annot.{{subset}}", subset=SUBSETS)

rule subset_reads:
    input:
        r1="../fastq/{sample}_1.fastq.gz",
        r2="../fastq/{sample}_2.fastq.gz"
    output:
        r1="{sample}_1.{subset}.fastq.gz",
        r2="{sample}_2.{subset}.fastq.gz"
    shell:
        """
        (gunzip -c {input.r1} || true) | head -n {wildcards.subset} | gzip -9c > {output.r1}
        (gunzip -c {input.r2} || true) | head -n {wildcards.subset} | gzip -9c > {output.r2}
        """

rule assemble:
    input:
        r1 = f"{SAMPLE}_1.{{subset}}.fastq.gz",
        r2 = f"{SAMPLE}_2.{{subset}}.fastq.gz"
    output:
        dir = directory(f"{SAMPLE}_assembly.{{subset}}"),
        assembly = f"{SAMPLE}-assembly.{{subset}}.fa"
    threads:
      8
    conda:
      "megahit"
    shell:
        """
        megahit -1 {input.r1} -2 {input.r2} -f -m 5e9 -t 4 -o {output.dir}
        cp {output.dir}/final.contigs.fa {output.assembly}
        """

rule quast:
    input:
        f"{SAMPLE}-assembly.{{subset}}.fa"
    output:
        directory(f"{SAMPLE}_quast.{{subset}}")
    threads:
      8
    conda:
      "megahit"
    shell:
        """
        quast {input} -o {output}
        """

rule annotate:
    input:
        f"{SAMPLE}-assembly.{{subset}}.fa"
    output:
        directory(f"{SAMPLE}_annot.{{subset}}")
    threads:
      8
    conda:
      "prokka"
    shell:
        """
        prokka --outdir {output} --prefix {SAMPLE} {input}
        """
