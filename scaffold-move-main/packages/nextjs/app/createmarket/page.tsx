"use client";
import React, { useState } from "react";
import type { NextPage } from "next";
import styles from "./page.module.css";
import { useRouter } from "next/navigation";


const MarketCreatePage: NextPage = () => {
  const router = useRouter();

  // ----- Hardcoded "previous market" data -----
  const previousMarketData = {
    title: "Old Title",
    participants: ["0x1234...abcd", "0x5678...efgh"],
    gradeTypes: ["A", "B", "C"],
    endDate: "2025-12-31"
  };

  // Local state for each field
  const [triger, setTriger] = useState(false);
  const [title, setTitle] = useState("");
  const [participantInput, setParticipantInput] = useState("");
  const [participants, setParticipants] = useState<string[]>([]);
  const [gradeTypeInput, setGradeTypeInput] = useState("");
  const [gradeTypes, setGradeTypes] = useState<string[]>([]);
  const [endDate, setEndDate] = useState("");

  // Handler to load the previous market format
  const handleUsePreviousMarket = () => {
    if(triger){
      setTriger(false);
      setTitle("");
      setParticipants([]);
      setGradeTypes([]);
      setEndDate("");
    }
    else{ 
      setTriger(true);
      setTitle(previousMarketData.title);
      setParticipants(previousMarketData.participants);
      setGradeTypes(previousMarketData.gradeTypes);
      setEndDate(previousMarketData.endDate);
    }
  };

  // Handlers for adding multiple participants
  const handleAddParticipant = () => {
    if (participantInput.trim()) {
      setParticipants([...participants, participantInput.trim()]);
      setParticipantInput("");
    }
  };

  // Handlers for adding multiple grade types
  const handleAddGradeType = () => {
    if (gradeTypeInput.trim()) {
      setGradeTypes([...gradeTypes, gradeTypeInput.trim()]);
      setGradeTypeInput("");
    }
  };

  // Form submission handler
  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    console.log({
      title,
      participants,
      gradeTypes,
      endDate
    });
    router.push("/")
  };

  return (
    <div className={styles.container}>
      <div className={styles.formOutline}>
        <h1 className={styles.formTitle}>Create a Marketplace</h1>
        <form onSubmit={handleSubmit}>
          {/* Title */}
          <div className={styles.formField}>
            <label className={styles.label}>Title</label>
            <input
              type="text"
              className={styles.inputField}
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Enter market title"
            />
          </div>

          {/* Participants */}
          <div className={styles.formField}>
            <label className={styles.label}>Add participants</label>
            <div className="flex gap-2 mb-2">
              <input
                type="text"
                className={`${styles.inputField} flex-grow`}
                value={participantInput}
                onChange={(e) => setParticipantInput(e.target.value)}
                placeholder="Enter participant wallet"
              />
              <button
                type="button"
                className={styles.addButton}
                onClick={handleAddParticipant}
              >
                +
              </button>
            </div>
            <ul className={styles.participantList}>
              {participants.map((p, idx) => (
                <li key={idx}>{p}</li>
              ))}
            </ul>
          </div>

          {/* Grade Types */}
          <div className={styles.formField}>
            <label className={styles.label}>Grade Types</label>
            <div className="flex gap-2 mb-2">
              <input
                type="text"
                className={`${styles.inputField} flex-grow`}
                value={gradeTypeInput}
                onChange={(e) => setGradeTypeInput(e.target.value)}
                placeholder="e.g. A, B, Pass, etc."
              />
              <button
                type="button"
                className={styles.addButton}
                onClick={handleAddGradeType}
              >
                +
              </button>
            </div>
            <ul className={styles.gradeList}>
              {gradeTypes.map((g, idx) => (
                <li key={idx}>{g}</li>
              ))}
            </ul>
          </div>

          {/* End Date */}
          <div className={styles.formField}>
            <label className={styles.label}>End Date</label>
            <input
              type="date"
              className={styles.inputField}
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
            />
          </div>
          {/* Button to load "previous" market data */}
          <button
            type="button"
            className={styles.prevMarketBtn}
            onClick={handleUsePreviousMarket}
          >
            {triger ? "Clear" : "Use Previous Market Format"}
          </button>

          {/* Submit Button */}
          <button type="submit" className={styles.submitBtn}>
            Submit
          </button>

        </form>
      </div>
    </div>
  );
};

export default MarketCreatePage;
