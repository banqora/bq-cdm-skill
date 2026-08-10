plugins {
    java
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.finos.cdm:cdm-java:7.0.0")
    testImplementation(platform("org.junit:junit-bom:5.11.4"))
    testImplementation("org.junit.jupiter:junit-jupiter")
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

tasks.test {
    useJUnitPlatform()
}
