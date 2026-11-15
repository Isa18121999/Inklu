#!/usr/bin/env node
/**
 * Publica 20 ofertas FICTICIAS desde la cuenta empresarial existente de INKLU.
 * Uso deliberado: SEED_DEMO_JOBS=true MONGODB_URI="..." node backend/scripts/seed-demo-jobs.js
 * No crea, modifica ni elimina cuentas de usuario.
 */
require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');
const Job = require('../models/Job');
const fixture = require('../data/demo-jobs.json');

async function main() {
  if (process.env.SEED_DEMO_JOBS !== 'true') {
    throw new Error('Carga bloqueada. Define SEED_DEMO_JOBS=true para confirmar la inserción de ofertas ficticias.');
  }
  if (!process.env.MONGODB_URI) throw new Error('Falta MONGODB_URI.');
  if (!Array.isArray(fixture.offers) || fixture.offers.length !== 20) {
    throw new Error('El fixture debe contener exactamente 20 ofertas de prueba.');
  }
  if (fixture.publisherEmail !== '18100102@ue.edu.pe') {
    throw new Error('El publicador configurado no coincide con la cuenta empresarial autorizada para esta carga.');
  }

  await mongoose.connect(process.env.MONGODB_URI);
  try {
    const publisher = await User.findOne({ email: fixture.publisherEmail.toLowerCase() });
    if (!publisher) {
      throw new Error(`No existe la cuenta ${fixture.publisherEmail}. No se crearon usuarios ni ofertas.`);
    }
    if (publisher.role !== 'company') {
      throw new Error(`La cuenta ${fixture.publisherEmail} no tiene rol empresarial (company). No se modificó la cuenta ni se publicaron ofertas.`);
    }

    let createdJobs = 0;
    let updatedJobs = 0;
    for (const offer of fixture.offers) {
      const jobData = {
        companyId: publisher._id,
        title: offer.title,
        description: `[OFERTA FICTICIA · DATOS DE PRUEBA] ${offer.description}`,
        category: offer.category,
        modality: offer.modality,
        location: offer.location,
        contractType: offer.contractType,
        salary: offer.salary,
        requiredSkills: offer.requiredSkills,
        preferredSkills: offer.preferredSkills,
        experienceRequired: offer.experienceRequired,
        accessibilityDetails: offer.accessibilityDetails,
        accessibility: offer.accessibility,
        active: true,
        isDemo: true
      };
      const existing = await Job.findOne({ companyId: publisher._id, title: offer.title, isDemo: true });
      if (existing) {
        await Job.updateOne({ _id: existing._id }, { $set: jobData });
        updatedJobs += 1;
      } else {
        await Job.create(jobData);
        createdJobs += 1;
      }
    }

    const published = await Job.find({ companyId: publisher._id, isDemo: true, active: true })
      .select('title companyId isDemo active')
      .lean();
    console.log(JSON.stringify({
      message: 'Ofertas ficticias publicadas desde la cuenta empresarial existente.',
      publisherEmail: publisher.email,
      publisherName: publisher.name,
      publisherRole: publisher.role,
      jobsCreated: createdJobs,
      jobsUpdated: updatedJobs,
      activeDemoJobsByPublisher: published.length,
      allBelongToPublisher: published.every(job => String(job.companyId) === String(publisher._id)),
      notice: 'Las 20 vacantes están marcadas isDemo=true; no son empleos reales.'
    }, null, 2));
  } finally {
    await mongoose.disconnect();
  }
}

main().catch(error => {
  console.error('No se pudieron publicar las ofertas ficticias:', error.message);
  process.exitCode = 1;
});
